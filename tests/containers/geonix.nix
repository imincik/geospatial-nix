{ inputs, config, pkgs, lib, ... }:

let
  geopkgs = inputs.geonix.packages.${pkgs.system};

  gdal-script = pkgs.writeScriptBin "gdal-script" ''
    echo "GDAL version:"
    ${geopkgs.gdal}/bin/gdalinfo --version
  '';

  python = pkgs.python3.withPackages (p: [
    geopkgs.python3-fiona
  ]);

in {
  name = "container-tests";

  packages = [ geopkgs.geonixcli ];

  containers.gdal-script.entrypoint = [ "/bin/sh" "-c" ];
  containers.gdal-script.startupCommand = "${gdal-script}/bin/gdal-script";
  containers.gdal-script.copyToRoot = null;

  containers.python.entrypoint = [ "${python}/bin/python" "-c"];
  containers.python.copyToRoot = null;

  processes.py-server.exec = "${pkgs.python3}/bin/python -m http.server";
  containers.py-server.entrypoint = [ "/bin/sh" "-c" ];
  containers.py-server.startupCommand = "${pkgs.python3}/bin/python -m http.server";
  containers.py-server.copyToRoot = null;
}
