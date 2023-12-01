{ nixpkgs, pkgs, pythonVersion, postgresqlVersion }:

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

  tiledb = pkgs.tiledb;

  gdal = (pkgs.gdal.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit geos libgeotiff libspatialite proj tiledb; };
  _gdal = gdal;

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
  ### PROJ
  #####################################################################

  proj = (pkgs.proj.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { };


  python-packages = rec { ### PYTHON PACKAGES

  #####################################################################
  ### PYTHON3-FIONA
  #####################################################################

  fiona = (pkgs."${pythonVersion}-fiona".overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit gdal; };

  #####################################################################
  ### PYTHON3-GDAL
  #####################################################################

  gdal = nixpkgs.${pythonVersion}.pkgs.toPythonModule (_gdal);   # nothing to override here

  #####################################################################
  ### PYTHON3-GEOPANDAS
  #####################################################################

  geopandas = (pkgs."${pythonVersion}-geopandas".overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit fiona pyproj shapely; };

  #####################################################################
  ### PYTHON3-OWSLIB
  #####################################################################

  owslib = (pkgs."${pythonVersion}-owslib".overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit pyproj; };

  #####################################################################
  ### PYTHON3-PSYCOPG
  #####################################################################

  psycopg = (pkgs."${pythonVersion}-psycopg".overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit shapely; };

  #####################################################################
  ### PYTHON3-PYPROJ
  #####################################################################

  pyproj = (pkgs."${pythonVersion}-pyproj".overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit proj shapely; };

  #####################################################################
  ### PYTHON3-PYQT5
  #####################################################################

  pyqt5 = pkgs."${pythonVersion}-pyqt5";  # nothing to override here

  #####################################################################
  ### PYTHON3-RASTERIO
  #####################################################################

  rasterio = (pkgs."${pythonVersion}-rasterio".overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit gdal shapely; };

  #####################################################################
  ### PYTHON3-SHAPELY
  #####################################################################

  shapely = (pkgs."${pythonVersion}-shapely".overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit geos; };

  }; ### PYTHON PACKAGES


  postgresql-packages = rec { ### POSTGRESQL PACKAGES

  #####################################################################
  ### POSTGIS
  #####################################################################

  postgis = (pkgs."${postgresqlVersion}-postgis".overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit gdal geos proj; };

  }; ### POSTGRESQL PACKAGES


  #####################################################################
  ### GRASS
  #####################################################################

  grass = (pkgs.grass.overrideAttrs (old: {

    # >>> CUSTOMIZE HERE

  })).override { inherit gdal geos pdal proj; };


  #####################################################################
  ### QGIS
  #####################################################################

  # QGIS
  qgis-unwrapped =
    let
      qgis-python =
        let
          packageOverrides = final: prev: {
            pyqt5 = python-packages.pyqt5;
            owslib = python-packages.owslib;
            gdal = python-packages.gdal;
          };
        in
        nixpkgs.${pythonVersion}.override { inherit packageOverrides; self = qgis-python; };
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
            pyqt5 = python-packages.pyqt5;
            owslib = python-packages.owslib;
            gdal = python-packages.gdal;
          };
        in
        nixpkgs.${pythonVersion}.override { inherit packageOverrides; self = qgis-python; };
    in
    (pkgs.qgis-ltr-unwrapped.overrideAttrs (old: {

      # >>> CUSTOMIZE HERE

    })).override {
        inherit geos gdal libspatialindex libspatialite pdal proj;
        python3 = qgis-python;
    };

  qgis-ltr = pkgs.qgis-ltr.override { qgis-ltr-unwrapped = qgis-ltr-unwrapped; };

}
