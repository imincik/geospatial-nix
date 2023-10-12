{ inputs, pkgs, ... }:

let
  geopkgs = inputs.geonix.packages.${pkgs.system};

in {
  # https://devenv.sh/packages/
  packages = [
    geopkgs.gdal
    geopkgs.pdal
    # geopkgs.qgis
  ];

  # https://devenv.sh/scripts/
  scripts.geonix-help.exec = ''
    echo -e "\nWelcome in Geonix shell ."

    echo "Software versions:"
    echo " * GDAL: ${geopkgs.gdal.version}"
    echo " * PDAL: ${geopkgs.pdal.version}"

    echo -e "\nRun 'psql' command to connect to Postgresql DB."
  '';

  # https://devenv.sh/services/
  services.postgres = {
    enable = true;
    extensions = e: [geopkgs.postgresql-postgis];

    initdbArgs = [
      "--locale=en_US.UTF-8"
      "--encoding=UTF8"
    ];
  };

  starship.enable = true;

  enterShell = ''
    geonix-help
  '';
}
