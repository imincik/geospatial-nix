#! /usr/bin/env bash

# Pull package from nixpkgs master branch and show diff if any.
# Usage: nixpkgs-diff.sh <PACKAGE>
#
# Note: package name for Python packages is python3Packages.<PACKAGE>

set -Eeuo pipefail

package="$1"

repo="https://github.com/NixOS/nixpkgs.git"
nixpkgs_dir="../nixpkgs"

nixpkgs_file=$(nix --experimental-features 'nix-command flakes' --accept-flake-config \
    eval --raw nixpkgs\#"$package".meta.position \
    | sed -n -e 's/^.*\/pkgs\///p' \
    | sed 's/:.*//' \
)
nixpkgs_path=$(dirname "$nixpkgs_file")
echo "Found package in nixpkgs: $nixpkgs_path"

nixpkgs_pname=$(nix --experimental-features 'nix-command flakes' --accept-flake-config \
    eval --raw nixpkgs\#"$package".pname
)
echo "Nixpkgs pname: $nixpkgs_pname"

if [ ! -d "$nixpkgs_dir" ]; then
    echo "Cloning nixpkgs to $nixpkgs_dir ..."

    mkdir -pv $nixpkgs_dir
    git clone --depth 1 $repo $nixpkgs_dir
else
    echo "Updating nixpkgs in $nixpkgs_dir ..."
    git -C "$nixpkgs_dir" checkout master
    git -C "$nixpkgs_dir" pull
fi

echo -e "\nPulling $nixpkgs_pname ..."
cp -v $nixpkgs_dir/pkgs/"$nixpkgs_path"/* pkgs/"$nixpkgs_pname"/

echo
git diff -- pkgs/"$nixpkgs_pname"
