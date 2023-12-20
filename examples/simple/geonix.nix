{ inputs, config, pkgs, lib, ... }:

let
  # Get Geospatial NIX packages
  geopkgs = inputs.geonix.packages.${pkgs.system};

in {
  # https://devenv.sh/reference/options/

  packages = [
    # packages from Nixpkgs
    pkgs.hello

    # packages from Geospatial NIX
    geopkgs.geonixcli
    geopkgs.gdal
    # geopkgs.qgis
  ];
}
