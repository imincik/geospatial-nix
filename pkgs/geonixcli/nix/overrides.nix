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
  ### PYTHON3-FIONA
  #####################################################################

  python3-fiona = (pkgs.python3-fiona.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit gdal; };

  #####################################################################
  ### PYTHON3-GDAL
  #####################################################################

  python3-gdal = nixpkgs.python3.pkgs.toPythonModule (gdal);   # nothing to override here

  #####################################################################
  ### PYTHON3-GEOPANDAS
  #####################################################################

  python3-geopandas = (pkgs.python3-geopandas.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { fiona = python3-fiona; pyproj = python3-pyproj; shapely = python3-shapely; };

  #####################################################################
  ### PYTHON3-OWSLIB
  #####################################################################

  python3-owslib = (pkgs.python3-owslib.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { pyproj = python3-pyproj; };

  #####################################################################
  ### PYTHON3-PSYCOPG
  #####################################################################

  python3-psycopg = (pkgs.python3-psycopg.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { shapely = python3-shapely; };

  #####################################################################
  ### PYTHON3-PYPROJ
  #####################################################################

  python3-pyproj = (pkgs.python3-pyproj.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit proj; shapely = python3-shapely; };

  #####################################################################
  ### PYTHON3-PYQT5
  #####################################################################

  python3-pyqt5 = pkgs.python3-pyqt5;  # nothing to override here

  #####################################################################
  ### PYTHON3-RASTERIO
  #####################################################################

  python3-rasterio = (pkgs.python3-rasterio.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit gdal; shapely = python3-shapely; };

  #####################################################################
  ### PYTHON3-SHAPELY
  #####################################################################

  python3-shapely = (pkgs.python3-shapely.overrideAttrs (old: {

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
            pyqt5 = python3-pyqt5;
            owslib = python3-owslib;
            gdal = python3-gdal;
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
            pyqt5 = python3-pyqt5;
            owslib = python3-owslib;
            gdal = python3-gdal;
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
      python3-fiona
      python3-gdal
      python3-geopandas
      python3-owslib
      python3-pyproj
      python3-rasterio
      python3-shapely;

    # Available parameters:
    # extraPythonPackages = with nixpkgs.python3.pkgs; [
    #   <PACKAGE>
    #   ipython
    # ];

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
