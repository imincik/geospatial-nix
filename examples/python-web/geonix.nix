{ inputs, config, lib, pkgs, ... }:

let
  # Get Geospatial NIX packages
  geopkgs = inputs.geonix.packages.${pkgs.system};

  python = pkgs.python3.withPackages (p: [
    # packages from Geospatial NIX
    geopkgs.python3-psycopg
    geopkgs.python3-shapely

    # packages from Nixpkgs 
    pkgs.python3.pkgs.matplotlib
  ]);

in
{
  # https://devenv.sh/packages/
  packages = [
    geopkgs.geonixcli
  ];

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
    enable = !config.container.isBuilding;  # don't include in container
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

  processes.flask-run.exec = "poetry run flask --app src/python_app run --host 0.0.0.0 ${lib.optionalString (!config.container.isBuilding) "--reload"}";

  containers.shell = {
    # don't copy `.venv` directory to image (it is not portable)
    copyToRoot = builtins.filterSource (path: type: baseNameOf path != ".venv") ./.;
    startupCommand = config.procfileScript;
  };

  pre-commit.hooks = {
    black.enable = true;
  };
}
