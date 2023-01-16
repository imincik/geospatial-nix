{ lib
, dockerTools

, bash
, coreutils
, fakeNss

, python3
, python3-fiona
, python3-gdal
, python3-geopandas
, python3-owslib
, python3-pyproj
, python3-rasterio
, python3-shapely

, extraPythonPackages ? []

}:

let
  py = python3;

  pythonPackage = py.withPackages (p: [
    python3-fiona
    python3-gdal
    python3-geopandas
    python3-owslib
    python3-pyproj
    python3-rasterio
    python3-shapely
  ] ++ extraPythonPackages);


in
dockerTools.buildLayeredImage
  {
    name = "geonix-python";
    tag = "latest";

    # Breaks reproducibility by setting current timestamp during each build.
    # created = "now";

    contents = [
      pythonPackage

      bash
      coreutils
      fakeNss
    ];

    extraCommands = ''
      mkdir data tmp
      chmod 777 data tmp
    '';

    maxLayers = 100;

    config = {
      Env = [
        "IPYTHONDIR=/tmp"
      ];

      User = "nobody";
      Entrypoint = [ "${pythonPackage}/bin/python" ];

      Volumes = {
        "/data" = { };
      };
    };
  } // {
  meta = {
    description = "Python OCI compatible container image";
    homepage = "https://github.com/imincik/geonix";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.imincik ];
    platforms = lib.platforms.linux;
  };
}
