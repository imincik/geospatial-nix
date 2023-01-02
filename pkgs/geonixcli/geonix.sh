#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] command arg1 [arg2...]

Geonix convenience tools.

Available options:

-h, --help          Print this help and exit
-v, --verbose       Print script debug info

Available commands:

search PACKAGE      Search for packages available in latest and pinned versions
                    of Nixpkgs and Geonix found in flake.lock file. To search
                    for multiple packages usage "PACKAGE-X|PACKAGE-Y" format.
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[1m' BOLD='\033[1m'
  else
    NOFORMAT='' BOLD=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
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
  [[ ${#args[@]} -lt 2 ]] \
      && die "Missing script command or arguments. Use --help to get more information."

  return 0
}

parse_params "$@"
setup_colors


NIX_FLAGS=( --show-trace --extra-experimental-features nix-command --extra-experimental-features flakes )

nix_search() {
    results=$(nix "${NIX_FLAGS[@]}" search --json "$1" "$2")

    if [ "$results" != "{}" ]; then
        # jq expression taken from devenv (https://github.com/cachix/devenv). Thank you !
        jq -r '[to_entries[] | {name: ("pkgs." + (.key | split(".") | del(.[0, 1]) | join("."))) } * (.value | { version, description})] | (.[0] |keys_unsorted | @tsv) , (["----", "-------", "-----------"] | @tsv), (.[]  |map(.) |@tsv)' <<< "$results"
    else
        echo "No packages found for $2"
    fi
}

geonix_search() {
    nix_search "$1" "$2" | sed "s/^pkgs./pkgs.geonix./"
}


# SEARCH COMMAND
if [ "${args[0]}" == "search" ]; then
    nixpkgs_rev=$(nix "${NIX_FLAGS[@]}" flake metadata  --json | jq --raw-output '.locks.nodes.nixpkgs.locked.rev' | cut -c1-7)
    geonix_rev=$(nix "${NIX_FLAGS[@]}" flake metadata  --json | jq --raw-output '.locks.nodes.geonix.locked.rev' | cut -c1-7)


    if [ "$nixpkgs_rev" != "null" ]; then
        echo -e "\n${BOLD}PACKAGES: nixpkgs/flake (rev: $nixpkgs_rev) ${NOFORMAT}"
        nix_search "nixpkgs/$nixpkgs_rev" "${args[@]:1}" | column -ts $'\t'
    fi

    echo -e "\n${BOLD}PACKAGES: nixpkgs/nixos-unstable ${NOFORMAT}"
    nix_search "nixpkgs/nixos-unstable" "${args[@]:1}" | column -ts $'\t'

    if [ "$geonix_rev" != "null" ]; then
        echo -e "\n${BOLD}PACKAGES: geonix/flake (rev: $geonix_rev) ${NOFORMAT}"
        geonix_search "github:imincik/geonix/$geonix_rev" "${args[@]:1}" | column -ts $'\t'
    fi

    echo -e "\n${BOLD}PACKAGES: geonix/master ${NOFORMAT}"
    geonix_search "github:imincik/geonix" "${args[@]:1}" | column -ts $'\t'

else
    die "Unknown command. Use --help to get more information."
fi

# vim: set ts=4 sts=4 sw=4 et:

