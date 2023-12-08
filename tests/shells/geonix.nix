{ inputs, pkgs, ... }:

let
  geopkgs = inputs.geonix.packages.${pkgs.system};

  python = pkgs.python3.withPackages (p: [
    geopkgs.python3-fiona
    pkgs.python3.pkgs.flask
  ]);

in
{
  packages = [
    geopkgs.geonixcli
    geopkgs.gdal
    pkgs.netcat
  ];

  languages.python = {
    enable = true;
    package = python;
  };

  services.postgres = {
    enable = true;
    extensions = e: [ geopkgs.postgresql-postgis ];
    listen_addresses = "127.0.0.1";
  };

  env.PYTHONPATH = "${python}/${python.sitePackages}";
  env.NIX_PYTHON_SITEPACKAGES = "${python}/${python.sitePackages}";
}
