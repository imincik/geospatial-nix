{ inputs, pkgs, ... }:

let
  geopkgs = inputs.geonix.packages.${pkgs.system};

in {
  # See https://devenv.sh/reference/options/ for complete list of configuration
  # options.

  # Use `geonix search` to search for packages.
  packages = [
    pkgs.hello

    geopkgs.geonixcli
    geopkgs.gdal
  ];

  # Enable this block to get PostgreSQL/PostGIS service.
  # Run `geonix up` in shell environment to launch all services.
  # services.postgres = {
  #   enable = true;
  #   extensions = e: [ geopkgs.postgresql-postgis ];
  # };

  enterShell = ''
    gdalinfo --version
  '';
}
