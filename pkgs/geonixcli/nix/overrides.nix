{ nixpkgs, pkgs }:

rec {

  # Place overrides under '>>> CUSTOMIZE HERE' line of desired package.

  # Run 'nix flake check' to check your code.
  # Run 'nix develop' to enter development shell to test packages.

  # Generic example

  # version = "XX.YY.ZZ";
  #
  # src = nixpkgs.fetchFromGitHub {
  #   owner = "<REPOSITORY-OWNER>";
  #   repo = "<REPOSITORY-NAME>";
  #   rev = "<GIT-REVISION>";
  #   hash = nixpkgs.lib.fakeHash;
  # };
  #
  # patches = [
  #   (nixpkgs.fetchpatch {
  #     name = "<PATCH-NAME>.patch";
  #     url = "https://github.com/<OWNER>/<REPO>/commit/<REVISION>.patch";
  #     hash = nixpkgs.lib.fakeHash;
  #   })
  #
  #   (nixpkgs.fetchpatch {
  #     name = "<PATCH-NAME>.patch";
  #     url = "https://github.com/<OWNER>/<REPO>/commit/<REVISION>.patch";
  #     hash = nixpkgs.lib.fakeHash;
  #   })
  # ];
  #
  # cmakeFlags = old.cmakeFlags ++ [
  #   "-D<FLAG_X>=ON"
  #   "-D<FLAG_Y>=OFF"
  # ];


  # Example of GDAL customization

  # version = "1000.0.0";
  #
  # patches = [
  #   (nixpkgs.fetchpatch {
  #     name = "test-patch.patch";
  #     url = "https://github.com/imincik/gdal/commit/6f91f4f91beea38cd8085866310589f4bb34caac.patch";
  #     hash = "sha256-NinvL2aMabkofX5D2RGR0cokj9rWGvcTjdC4v/Iehe8=";
  #   })
  # ];


  #####################################################################
  ### GEONIXCLI
  #####################################################################

  geonixcli = pkgs.geonixcli; # don't remove or override this package !

  #####################################################################
  ### GDAL
  #####################################################################

  gdal = (pkgs.gdal.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit geos libgeotiff libspatialite proj; };

  #####################################################################
  ### GEOS
  #####################################################################

  geos = (pkgs.geos.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { };

  #####################################################################
  ### LIBGEOTIFF
  #####################################################################

  libgeotiff = (pkgs.libgeotiff.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit proj; };


  #####################################################################
  ### LIBRTTOPO
  #####################################################################

  librttopo = (pkgs.librttopo.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit geos; };


  #####################################################################
  ### LIBSPATIALINDEX
  #####################################################################

  libspatialindex = (pkgs.libspatialindex.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { };


  #####################################################################
  ### LIBSPATIALITE
  #####################################################################

  libspatialite = (pkgs.libspatialite.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit geos librttopo proj; };


  #####################################################################
  ### PDAL
  #####################################################################

  pdal = (pkgs.pdal.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit gdal libgeotiff; };


  #####################################################################
  ### POSTGIS
  #####################################################################

  postgis = (pkgs.postgis.overrideAttrs (fina: prev: {

    # >>> CUSTOMIZE HERE

  })).override { inherit gdal geos proj; };


  #####################################################################
  ### PROJ
  #####################################################################

  proj = (pkgs.proj.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { };

  #####################################################################
  ### PYTHON-FIONA
  #####################################################################

  python-fiona = (pkgs.python-fiona.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit gdal; };

  #####################################################################
  ### PYTHON-GDAL
  #####################################################################

  python-gdal = nixpkgs.python3.pkgs.toPythonModule (gdal);   # nothing to override here

  #####################################################################
  ### PYTHON-GEOPANDAS
  #####################################################################

  python-geopandas = (pkgs.python-geopandas.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { fiona = python-fiona; pyproj = python-pyproj; shapely = python-shapely; };

  #####################################################################
  ### PYTHON-OWSLIB
  #####################################################################

  python-owslib = (pkgs.python-owslib.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { pyproj = python-pyproj; };

  #####################################################################
  ### PYTHON-PSYCOPG
  #####################################################################

  python-psycopg = (pkgs.python-psycopg.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { shapely = python-shapely; };

  #####################################################################
  ### PYTHON-PYPROJ
  #####################################################################

  python-pyproj = (pkgs.python-pyproj.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit proj; shapely = python-shapely; };

  #####################################################################
  ### PYTHON-PYQT5
  #####################################################################

  python-pyqt5 = pkgs.python-pyqt5;  # nothing to override here

  #####################################################################
  ### PYTHON-RASTERIO
  #####################################################################

  python-rasterio = (pkgs.python-rasterio.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit gdal; shapely = python-shapely; };

  #####################################################################
  ### PYTHON-SHAPELY
  #####################################################################

  python-shapely = (pkgs.python-shapely.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit geos; };

  #####################################################################
  ### QGIS
  #####################################################################

  # QGIS
  qgis-unwrapped =
    let
      qgis-python =
        let
          packageOverrides = final: prev: {
            pyqt5 = python-pyqt5;
            owslib = python-owslib;
            gdal = python-gdal;
          };
        in
        nixpkgs.python3.override { inherit packageOverrides; self = qgis-python; };
    in
    (pkgs.qgis-unwrapped.overrideAttrs (old: {

      # >>> CUSTOMIZE HERE

    })).override {
        inherit geos gdal libspatialindex libspatialite pdal proj;
        python3 = qgis-python;
    };

  qgis = pkgs.qgis.override { qgis-unwrapped = qgis-unwrapped; };

  # QGIS-LTR
  qgis-ltr-unwrapped =
    let
      qgis-python =
        let
          packageOverrides = final: prev: {
            pyqt5 = python-pyqt5;
            owslib = python-owslib;
            gdal = python-gdal;
          };
        in
        nixpkgs.python3.override { inherit packageOverrides; self = qgis-python; };
    in
    (pkgs.qgis-ltr-unwrapped.overrideAttrs (old: {

      # >>> CUSTOMIZE HERE

    })).override {
        inherit geos gdal libspatialindex libspatialite pdal proj;
        python3 = qgis-python;
    };

  qgis-ltr = pkgs.qgis-ltr.override { qgis-ltr-unwrapped = qgis-ltr-unwrapped; };

  #####################################################################
  ### IMAGE: GEONIX-PYTHON-IMAGE
  #####################################################################

  geonix-python-image = pkgs.geonix-python-image.override {
    inherit
      python-fiona
      python-gdal
      python-geopandas
      python-owslib
      python-pyproj
      python-rasterio
      python-shapely;

    # >>> CUSTOMIZE HERE

  };

  #####################################################################
  ### IMAGE: GEONIX-POSTGRESQL-IMAGE
  #####################################################################

  geonix-postgresql-image = pkgs.geonix-postgresql-image.override {
    inherit postgis;

    # Available parameters:
    # extraPostgresqlPackages = with nixpkgs.postgresql.pkgs; [
    #   <PACKAGE>
    #   pgrouting
    # ];

    # >>> CUSTOMIZE HERE

  };
}
