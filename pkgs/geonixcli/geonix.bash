#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

function usage {
  cat <<EOF
Usage: geonix [-h] [-v] command arg1 [arg2...]

Geonix environment management script.

Available options:

-h, --help          Print this help and exit
-v, --verbose       Print script debug info

Available commands:

init                Initialize current directory with flake.nix and geonix.nix
                    files.

search PACKAGE/     Search for packages or container images available in Geonix
       IMAGE        or Nixpkgs repository. Search is perfomed for revisions
                    according flake.lock file and latest revisions.

                    To search for multiple package names separate them with
                    pipe ("PACKAGE-X|PACKAGE-Y").

build PACKAGE/      Build Geonix package of container image in revision
      IMAGE         according flake.lock file. This command is mostly useful
                    for building and retrieving container images.

                    Note: this command can't be used to get container
                    images on macOS.

override            Create override template file overrides.nix in current
                    directory to build customized Geonix packages.

                    To build customized packages:

                    * add overrides.nix file to git

                    * use it as overridesFile parameter in geonix.lib.getPackages
                      function in flake.nix

                    * edit overrides.nix file
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
  msg "warning: $msg"
}

function die {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "error: $msg"
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

parse_params "$@"
setup_colors


NIX_FLAGS=( --no-warn-dirty --extra-experimental-features nix-command --extra-experimental-features flakes )

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

        nixpkgs_ref=$( \
            nix "${NIX_FLAGS[@]}" flake metadata  --json \
            | jq --raw-output '.locks.nodes.nixpkgs.original.ref' \
            | sed 's|/$||'
        )

        nixpkgs_rev=$( \
            nix "${NIX_FLAGS[@]}" flake metadata  --json \
            | jq --raw-output '.locks.nodes.nixpkgs.locked.rev' \
            | cut -c1-7 \
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

        geonix_ref=$( \
            nix "${NIX_FLAGS[@]}" flake metadata  --json \
            | jq --raw-output '.locks.nodes.geonix.original.ref' \
            | sed 's|/$||'
        )

        geonix_rev=$( \
            nix "${NIX_FLAGS[@]}" flake metadata  --json \
            | jq --raw-output '.locks.nodes.geonix.locked.rev' \
            | cut -c1-7 \
        )
    fi
}


# INIT
if [ "${args[0]}" == "init" ]; then

    for init_file in "flake.nix" "geonix.nix"; do
        if [ -f "$(pwd)/$init_file" ]; then
            die "$init_file file already exists in $(pwd) directory."
        fi
    done

    for init_file in "flake.nix" "geonix.nix"; do
        cp "$GEONIX_NIX_DIR"/$init_file "$(pwd)"/$init_file
        chmod u+w "$(pwd)"/$init_file

        echo "$init_file created in $(pwd)/$init_file."
    done

    echo "Add all files to git before use !"


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
                    | { name: ("pkgs.nixpkgs." + (.key | split(".") | del(.[0, 1]) | join("."))) }
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
        nix_search "$1" "$2" | sed "s/^pkgs.nixpkgs./pkgs.geonix./"
    }

    if [ "$nixpkgs_exists" != "null" ]; then

        if [ "$nixpkgs_rev" != "null" ]; then
            echo -e "\n${BOLD}$nixpkgs_url/$nixpkgs_rev ${NOFORMAT}"
            nix_search "$nixpkgs_url/$nixpkgs_rev" "${args[@]:1}" | column -ts $'\t'
        fi

        if [ "$nixpkgs_ref" != "null" ]; then
            echo -e "\n${BOLD}$nixpkgs_url/$nixpkgs_ref ${NOFORMAT}"
            nix_search "$nixpkgs_url/$nixpkgs_ref" "${args[@]:1}" | column -ts $'\t'
        else
            echo -e "\n${BOLD}$nixpkgs_url ${NOFORMAT}"
            nix_search "$nixpkgs_url" "${args[@]:1}" | column -ts $'\t'
        fi
    fi

    if [ "$geonix_exists" != "null" ]; then

        if [ "$geonix_rev" != "null" ]; then
            echo -e "\n${BOLD}$geonix_url/$geonix_rev ${NOFORMAT}"
            geonix_search "$geonix_url/$geonix_rev" "${args[@]:1}" \
                | grep -v "\-unwrapped\|\-all-packages" \
                | column -ts $'\t'
        fi

        if [ "$geonix_ref" != "null" ]; then
            echo -e "\n${BOLD}$geonix_url/$geonix_ref ${NOFORMAT}"
            geonix_search "$geonix_url/$geonix_ref" "${args[@]:1}" \
                | grep -v "\-unwrapped\|\-all-packages" \
                | column -ts $'\t'
        else
            echo -e "\n${BOLD}$geonix_url ${NOFORMAT}"
            geonix_search "$geonix_url" "${args[@]:1}" \
                | grep -v "\-unwrapped\|\-all-packages" \
                | column -ts $'\t'
        fi
    fi


# BUILD
elif [ "${args[0]}" == "build" ]; then

    [[ ${#args[@]} -lt 2 ]] \
        && die "Missing image name. Use --help to get more information."

    image="${args[1]}"

    get_nixpkgs_metadata
    get_geonix_metadata

    if [ "$geonix_exists" != "null" ] && [ "$geonix_rev" != "null" ]; then
        nix build --accept-flake-config "$geonix_url/$geonix_rev#$image"
    elif [ "$geonix_exists" != "null" ] && [ "$geonix_rev" == "null" ]; then
        warn "Geonix revision not found in flake.lock file, building from the latest revision"
        nix build --accept-flake-config "$geonix_url#$image"
    else
        die "Geonix input not found flake.lock file"
    fi


# OVERRIDE
elif [ "${args[0]}" == "override" ]; then

    if [ -f "$(pwd)/overrides.nix" ]; then
        die "Override template file already exists in $(pwd) directory."
    else
        cp "$GEONIX_NIX_DIR"/overrides.nix "$(pwd)"/overrides.nix
        chmod u+w "$(pwd)"/overrides.nix

        echo "Override template file created in $(pwd)/overrides.nix ."
        echo "Add all files to git before use !"
    fi


# UNKNOWN
else
    die "Unknown command '${args[0]}'. Use --help to get more information."
fi

# vim: set ts=4 sts=4 sw=4 et:

