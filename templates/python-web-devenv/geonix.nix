{ inputs, pkgs, ... }:

let
  # Get Geospatial NIX packages
  geopkgs = inputs.geonix.packages.${pkgs.system};

  python = pkgs.python3.withPackages (p: [
    # packages from Geospatial NIX
    geopkgs.geonixcli  # FIXME: doesn't work
    geopkgs.python3-psycopg
    geopkgs.python3-shapely

    # packages from Nixpkgs 
    pkgs.python3.pkgs.matplotlib
  ]);

in
{
  # https://devenv.sh/packages/
  packages = [ ];

  # https://devenv.sh/languages/
  languages.python = {
    enable = true;
    package = python;
    poetry.enable = true;
    poetry.activate.enable = true;
    poetry.install.enable = true;
  };

  # https://devenv.sh/services/
  services.postgres = {
    enable = true;
    listen_addresses = "127.0.0.1";
    port = 15432;

    extensions = e: [ geopkgs.postgresql-postgis ];

    initdbArgs = [
      "--locale=en_US.UTF-8"
      "--encoding=UTF8"
    ];

    settings =  {
      # verbose logging
      log_connections = "on";
      log_duration = "on";
      log_statement = "all";
      log_disconnections = "on";
      log_destination = "stderr";
    };
  };

  env.PYTHONPATH = "${python}/${python.sitePackages}";
  env.NIX_PYTHON_SITEPACKAGES = "${python}/${python.sitePackages}";
}
