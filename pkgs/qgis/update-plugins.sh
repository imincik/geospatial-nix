#!/usr/bin/env nix-shell
#! nix-shell -i bash -p python3Packages.lxml

# Update QGIS plugins.
# Usage: update-plugins.sh

set -Eeuo pipefail

QGIS_PACKAGES=( qgis qgis-ltr )
QGIS_PLUGINS_XML_URL="https://plugins.qgis.org/plugins/plugins.xml"

for package in "${QGIS_PACKAGES[@]}"; do
    version=$(nix eval --raw .#"$package".version)
    major_version=$(echo "$version" | awk -F "." '{print $1 "." $2}')

    curl $QGIS_PLUGINS_XML_URL?qgis="$major_version" -o "$package"-plugins.xml

    python ./update-plugins.py "$package"-plugins.xml > "$package"-plugins.nix
done
