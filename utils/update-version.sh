#! /usr/bin/env bash
#
# Update package to the latest upstream version. Pretty naive script, but must
# be good for now.
# Usage: update-version.sh <PACKAGE>

# GITHUB_API_TOKEN must be used to prevent low rate limit for non authenticated API
# requests. Token must be in format "USERNAME:TOKEN"

set -Eeuo pipefail

package=$1

# get GitHub repo and owner
gh_repo_url="$(nix --experimental-features 'nix-command flakes' --accept-flake-config \
    eval --raw .\#"$package".src.gitRepoUrl \
)"
owner="$(echo "$gh_repo_url" | awk -F '/' '{print $4}')"
repo="$(echo "$gh_repo_url" | awk -F '/' '{print $5}' | sed 's/\..*//')"

echo "GitHub owner: $owner"
echo "GitHub repo: $repo"

# get latest upstream version
if [ "$package" != "qgis-ltr" ]; then
    latest_tag=$(\
        curl --user "$GITHUB_API_TOKEN" --silent "https://api.github.com/repos/$owner/$repo/releases" \
        | jq -r '.[].tag_name' \
        | grep -E '^(v)?(final-)?[0-9](\.|_)[0-9]*(\.|_)[0-9]*$' \
        | sort --version-sort --reverse \
        | head -n 1
    )
else
    # QGIS LTR specific tag search
    # !! Update code below when new major QGIS LTR version is released !!
    latest_tag=$(\
            curl --user "$GITHUB_API_TOKEN" --silent "https://api.github.com/repos/$owner/$repo/releases" \
            | jq -r '.[].tag_name' \
            | grep -E '^final-3_22_[0-9]*$' \
            | sort --version-sort --reverse \
            | head -n 1
    )
fi

# get version
src_version=$(echo "$latest_tag" | sed 's/_/./g' | sed 's/[a-zA-Z\-]//g')

# get hash
src_hash="$(nix-prefetch-github "$owner" "$repo" --rev "$latest_tag" | jq -r '.sha256')"

echo "Latest upstream version: $src_version"
echo "Latest upstream hash: $src_hash"

# detect nix file (assume that file containing meta will contain also version
# and hash values)
nix_file="$(nix --experimental-features 'nix-command flakes' --accept-flake-config \
    eval --raw .\#"$package".meta.position \
    | sed -n -e 's/^.*\/pkgs\///p' \
    | sed 's/:.*//' \
)"

echo "Nix file: $nix_file"

# update version and hash in nix file
sed -i " /1/,/fetchFromGitHub/ s|version = \".*\";|version = \"${src_version}\";|" pkgs/"$nix_file"
sed -i "/fetchFromGitHub/,/};/ s|hash = \".*\";|hash = \"sha256-${src_hash}\";|" pkgs/"$nix_file"

echo "Git diff after update:"
git diff
