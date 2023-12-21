# See https://devenv.sh/reference/options/ for complete list of configuration
# options.

{ inputs, config, pkgs, lib, ... }:

let
  geopkgs = inputs.geonix.packages.${pkgs.system};

  # Enable this block to get Python environment.

  # python = pkgs.python3.withPackages (p: [
  #   # packages from Geospatial NIX
  #   geopkgs.python3-fiona

  #   # packages from Nixpkgs 
  #   pkgs.python3.pkgs.numpy
  # ]);

in {
  # Run `TODO` to enter shell environment.
  # Use `geonix search` to search for packages.
  packages = [
    pkgs.hello

    geopkgs.geonixcli
    geopkgs.gdal
  ];

  # Enable this block to get Python environment.

  # languages.python = {
  #   enable = true;
  #   package = python;
  #   poetry.enable = true;
  #   poetry.activate.enable = true;
  #   poetry.install.enable = true;
  # };

  # Enable this block to get PostgreSQL/PostGIS service.
  # Run `geonix up` in shell environment to launch all services.

  # services.postgres = {
  #   enable = !config.container.isBuilding;  # return `false` if building container
  #   extensions = e: [ geopkgs.postgresql-postgis ];
  #   listen_addresses = "127.0.0.1";
  # };

  enterShell = ''
    gdalinfo --version
  '';
}
