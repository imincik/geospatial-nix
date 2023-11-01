{ inputs, pkgs, ... }:

let
  geopkgs = inputs.geonix.packages.${pkgs.system};

  pythonPackage = pkgs.python3.withPackages (p: [
    # geonix packages
    geopkgs.python3-psycopg
    geopkgs.python3-shapely

    # nixpkgs packages
    pkgs.python3.pkgs.matplotlib
  ]);

in
{
  # https://devenv.sh/packages/
  packages = [ ];

  # https://devenv.sh/languages/
  languages.python = {
    enable = true;
    package = pythonPackage;
    poetry.enable = true;
    poetry.activate.enable = true;
    poetry.install.enable = true;
  };

  # https://devenv.sh/services/
  services.postgres = {
    enable = true;
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

  env.PYTHONPATH = "${pythonPackage}/${pythonPackage.sitePackages}";

  starship.enable = true;
}
