#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

function usage {
cat <<EOF
Usage: geonix [-h] [-v] command arg1 [arg2...]

Available options:

-h, --help          Print this help and exit
-v, --verbose       Print script debug info

Available commands:

init                Initialize current directory with initial files.

shell               Launch shell environment.

up                  Start processes configured in geonix.nix.
                    See: http://devenv.sh/processes

search PACKAGE      Search for packages available in Geospatial NIX or Nixpkgs
                    repository. Search is performed for revisions according
                    flake.lock file.

                    To search for multiple package names separate them with
                    pipe ("PACKAGE-X|PACKAGE-Y").

update              Update Geospatial NIX packages and environment
                    (will update flake.lock file).

container NAME      Build and import container image to Docker local registry.

                    See: https://devenv.sh/containers

override            Create overrides.nix template file in current
                    directory for building customized Geospatial NIX packages.

EOF
  exit
}

function cleanup {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

function setup_colors {
  if [[ -t 2 ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[1m' BOLD='\033[1m'
  else
    NOFORMAT='' BOLD=''
  fi
}

function msg {
  echo >&2 "${1-}"
}

function warn {
  local msg=$1
  msg "WARNING: $msg"
}

function die {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "ERROR: $msg"
  exit "$code"
}

function parse_params {
  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
  [[ ${#args[@]} -lt 1 ]] \
      && die "Missing script command or arguments. Use --help to get more information."

  return 0
}

NIX_FLAGS=( --accept-flake-config --no-warn-dirty --extra-experimental-features nix-command --extra-experimental-features flakes )

function nix_version {
    nix --version | grep --only-matching --extended-regexp '[0-9]+.[0-9]+.[0-9]+'
}

function versionge {
    [ "$1" == "$(echo -e "$1\n$2" | sort --version-sort | tail -n1)" ]
}

function get_nixpkgs_metadata {
    nixpkgs_exists=$( \
        nix "${NIX_FLAGS[@]}" flake metadata  --json \
        | jq --raw-output '.locks.nodes.nixpkgs' \
    )

    if [ "$nixpkgs_exists" != "null" ]; then

        nixpkgs_url=$( \
            nix "${NIX_FLAGS[@]}" flake metadata  --json \
            | jq --raw-output '
                (.locks.nodes.nixpkgs.original.type)
                + ":"
                + (.locks.nodes.nixpkgs.original.owner)
                + "/"
                + (.locks.nodes.nixpkgs.original.repo)
            ' \
        )

        # shellcheck disable=SC2034
        nixpkgs_ref=$( \
            nix "${NIX_FLAGS[@]}" flake metadata  --json \
            | jq --raw-output '.locks.nodes.nixpkgs.original.ref' \
            | sed 's|/$||'
        )

        nixpkgs_rev=$( \
            nix "${NIX_FLAGS[@]}" flake metadata  --json \
            | jq --raw-output '.locks.nodes.nixpkgs.locked.rev' \
        )
    fi
}

function get_geonix_metadata {
    geonix_exists=$( \
        nix "${NIX_FLAGS[@]}" flake metadata  --json \
        | jq --raw-output '.locks.nodes.geonix' \
    )

    if [ "$geonix_exists" != "null" ]; then

        geonix_type=$( \
            nix "${NIX_FLAGS[@]}" flake metadata  --json \
            | jq --raw-output '.locks.nodes.geonix.original.type'
        )

        if [ "$geonix_type" == "github" ]; then

            geonix_url=$( \
                nix "${NIX_FLAGS[@]}" flake metadata  --json \
                | jq --raw-output '
                    (.locks.nodes.geonix.original.type)
                    + ":" + (.locks.nodes.geonix.original.owner)
                    + "/"
                    + (.locks.nodes.geonix.original.repo)
                ' \
            )

        elif [ "$geonix_type" == "path" ]; then

            geonix_url=$( \
                nix "${NIX_FLAGS[@]}" flake metadata  --json \
                | jq --raw-output '.locks.nodes.geonix.original.path' \
            )
        fi

        # shellcheck disable=SC2034
        geonix_ref=$( \
            nix "${NIX_FLAGS[@]}" flake metadata  --json \
            | jq --raw-output '.locks.nodes.geonix.original.ref' \
            | sed 's|/$||'
        )

        geonix_rev=$( \
            nix "${NIX_FLAGS[@]}" flake metadata  --json \
            | jq --raw-output '.locks.nodes.geonix.locked.rev' \
        )
    fi
}

function assemble_devenv {
    # see: https://github.com/cachix/devenv/blob/405a4c6a3fecfd2a7fb37cc13f4e760658e522e6/src/devenv.nix#L29

    DEVENV_DIR="$(pwd)/.devenv"
    export DEVENV_DIR
}


parse_params "$@"
setup_colors

# INIT
if [ "${args[0]}" == "init" ]; then

    for init_file in "flake.nix" "geonix.nix"; do
        if [ -f "$(pwd)/$init_file" ]; then
            die "$init_file file already exists in $(pwd) directory."
        fi
    done

    echo -e "\nWelcome to Geospatial NIX environment !\n"
    for init_file in "flake.nix" "geonix.nix" "dot-envrc"; do
        cp "$GEONIX_TEMPLATES_DIR"/init/$init_file "$(pwd)"/$init_file
        chmod u+w "$(pwd)"/$init_file

        echo "$init_file file created in $(pwd)/$init_file."
    done

    echo -e "\nStart by configuring the environment in geonix.nix file."
    echo
    echo "Rename dot-envrc file to .envrc to enable environment auto-loading using nix-direnv."
    echo
    echo "And don't forget to add all files to git."


# SHELL
elif [ "${args[0]}" == "shell" ]; then

    nix "${NIX_FLAGS[@]}" develop --impure "${args[@]:1}"


# UP
elif [ "${args[0]}" == "up" ]; then

    assemble_devenv

    procfilescript=$(nix "${NIX_FLAGS[@]}" build '.#devenv-up' --no-link --print-out-paths --impure)

    # shellcheck disable=SC2086
    if [ "$(cat $procfilescript|tail -n +2)" = "" ]; then
        die "No services defined in geonix.nix file."
    else
        exec $procfilescript
    fi


# SEARCH
elif [ "${args[0]}" == "search" ]; then

    [[ ${#args[@]} -lt 2 ]] \
        && die "Missing package search string. Use --help to get more information."

    get_nixpkgs_metadata
    get_geonix_metadata

    function nix_search {
        results=$(nix "${NIX_FLAGS[@]}" search --json "$1" "$2")

        if [ "$results" != "{}" ]; then
            # jq expression taken from devenv (https://github.com/cachix/devenv). Thank you !
            jq --raw-output '
                [
                    to_entries[]
                    | { name: ("pkgs." + (.key | split(".") | del(.[0, 1]) | join("."))) }
                    * (.value | { version, description})
                ]
                | (.[0] |keys_unsorted | @tsv)
                , (["----", "-------", "-----------"] | @tsv)
                , (.[]  |map(.) |@tsv)' <<< "$results"
        else
            echo "No packages found for $2"
        fi
    }

    function geonix_search {
        nix_search "$1" "$2" | sed "s/^pkgs./geopkgs./"
    }

    if [ "$nixpkgs_exists" != "null" ]; then

        if [ "$nixpkgs_rev" != "null" ]; then
            echo -e "\n${BOLD}$nixpkgs_url/$nixpkgs_rev ${NOFORMAT}"
            nix_search "$nixpkgs_url/$nixpkgs_rev" "${args[@]:1}" \
                | column -ts $'\t'
        fi
    fi

    if [ "$geonix_exists" != "null" ]; then

        if [ "$geonix_rev" != "null" ]; then
            echo -e "\n${BOLD}$geonix_url/$geonix_rev ${NOFORMAT}"
            geonix_search "$geonix_url/$geonix_rev" "${args[@]:1}" \
                | grep -v "unwrapped\|all-packages" \
                | column -ts $'\t'
        fi
    fi


# UPDATE
elif [ "${args[0]}" == "update" ]; then

    # `nix flake lock --update-input` was removed in nix 2.19
    if versionge "$(nix_version)" "2.19.0"; then
        # new syntax
        nix "${NIX_FLAGS[@]}" flake update geonix
    else
        # old syntax
        nix "${NIX_FLAGS[@]}" flake lock --update-input geonix
    fi


# CONTAINER
elif [ "${args[0]}" == "container" ]; then

    [[ ${#args[@]} -lt 2 ]] && die "Missing container name. Use --help to get more information."

    assemble_devenv

    container_name="$2"
    image_name=$(nix "${NIX_FLAGS[@]}" eval --raw ".#container-$container_name.imageName")

    export DEVENV_CONTAINER=1
    copy_script=$( \
        nix build ".#container-$container_name.copyToDockerDaemon" --no-link --print-out-paths --impure \
    )
    "$copy_script/bin/copy-to-docker-daemon"

    echo -e "\nRun docker container now:"
    echo "  docker run --rm -it $image_name:latest"
    echo "  docker run --rm -it $image_name:latest <COMMAND>"
    echo "  docker run --rm -p <PORT>:<PORT> $image_name:latest"


# OVERRIDE
elif [ "${args[0]}" == "override" ]; then

    if [ -f "$(pwd)/overrides.nix" ]; then
        die "Override template file already exists in $(pwd) directory."
    else
        cp "$GEONIX_TEMPLATES_DIR"/override/overrides.nix "$(pwd)"/overrides.nix
        chmod u+w "$(pwd)"/overrides.nix

        echo "Override template file created in $(pwd)/overrides.nix ."
        echo
        echo "Use overrides.nix file with customizePackages function."
        echo
        echo "Example usage in geonix.nix file:"
        echo "geopkgs = inputs.geonix.lib.customizePackages {        "
        echo "  nixpkgs = pkgs;                                      "
        echo "  geopkgs = inputs.geonix.packages.\${pkgs.system};     "
        echo "  overridesFile = ./overrides.nix;                     "
        echo "};                                                     "
        echo
        echo "And don't forget to add all files to git."
    fi


# HELP
elif [ "${args[0]}" == "help" ]; then
    usage


# UNKNOWN
else
    die "Unknown command '${args[0]}'. Use --help to get more information."
fi

# vim: set ts=4 sts=4 sw=4 et:

