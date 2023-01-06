{ lib
, dockerTools

, fakeNss
, python3
, python-fiona
, python-gdal
, python-geopandas
, python-owslib
, python-pyproj
, python-rasterio
, python-shapely

}:

let
  py = python3;

  pythonPackage = py.withPackages (p: [
    python-fiona
    python-gdal
    python-geopandas
    python-owslib
    python-pyproj
    python-rasterio
    python-shapely
  ]);

in
dockerTools.buildLayeredImage
  {
    name = "geonix-python";
    tag = "latest";

    # Breaks reproducibility by setting current timestamp during each build.
    # created = "now";

    contents = [ pythonPackage fakeNss ];

    maxLayers = 100;

    config = {
      User = "nobody";
      Entrypoint = [ "${pythonPackage}/bin/python" ];
    };
  } // {
  meta = {
    description = "PostgreSQL/PostGIS OCI compatible container image";
    homepage = "https://github.com/imincik/geonix";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.imincik ];
    platforms = lib.platforms.linux;
  };
}
