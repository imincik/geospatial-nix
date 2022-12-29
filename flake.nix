{
  description = "Geonix - geospatial environment for Nix";

  nixConfig.extra-substituters = [ "https://geonix.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "geonix.cachix.org-1:iyhIXkDLYLXbMhL3X3qOLBtRF8HEyAbhPXjjPeYsCl0=" ];

  nixConfig.bash-prompt = "\\[\\033[1m\\][geonix]\\[\\033\[m\\]\\040\\w >\\040";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ]
      (system:

        let
          # allow insecure QGIS dependency (QtWebkit)
          insecurePackages = [ "qtwebkit-5.212.0-alpha4" ];

          pkgs = import nixpkgs {
            inherit system;
            config = { permittedInsecurePackages = insecurePackages; };
          };

        in
        {

          # Each new package must be added to:
          # * packages
          # * all-packages

          #
          ### PACKAGES ###
          #

          packages = flake-utils.lib.filterPackages system rec {

            geos = pkgs.callPackage ./pkgs/geos { };
            libspatialindex = pkgs.callPackage ./pkgs/libspatialindex { };
            proj = pkgs.callPackage ./pkgs/proj { };

            libgeotiff = pkgs.callPackage ./pkgs/libgeotiff {
              inherit proj;
            };

            libspatialite = pkgs.callPackage ./pkgs/libspatialite {
              inherit geos proj;
            };

            gdal = pkgs.callPackage ./pkgs/gdal {
              inherit geos libgeotiff libspatialite proj;
            };

            pdal = pkgs.callPackage ./pkgs/pdal {
              inherit gdal libgeotiff;
            };


            # Python packages
            python-fiona = pkgs.python3.pkgs.callPackage ./pkgs/fiona {
              inherit gdal;
            };

            python-gdal = pkgs.python3.pkgs.toPythonModule (gdal.override {
              inherit geos libgeotiff libspatialite proj;
            });

            python-geopandas = pkgs.python3.pkgs.callPackage ./pkgs/geopandas {
              fiona = python-fiona;
              pyproj = python-pyproj;
              shapely = python-shapely;
            };

            python-owslib = pkgs.python3.pkgs.callPackage ./pkgs/owslib {
              pyproj = python-pyproj;
            };

            python-pyproj = pkgs.python3.pkgs.callPackage ./pkgs/pyproj {
              inherit proj;
              shapely = python-shapely;
            };

            python-rasterio = pkgs.python3.pkgs.callPackage ./pkgs/rasterio {
              inherit gdal;
              shapely = python-shapely;
            };

            python-shapely = pkgs.python3.pkgs.callPackage ./pkgs/shapely {
              inherit geos;
            };


            # PostgreSQL
            postgis = pkgs.callPackage ./pkgs/postgis/postgis.nix {
              inherit gdal geos proj;
            };


            # QGIS
            qgis =
              let
                qgis-python =
                  let
                    packageOverrides = final: prev: {
                      pyqt5 = prev.pyqt5.override { withLocation = true; };
                      owslib = python-owslib;
                      gdal = gdal;
                    };
                  in
                  pkgs.python3.override { inherit packageOverrides; self = qgis-python; };

                # geonix-grass = pkgs.grass.override {
                #   gdal = gdal;
                #   geos = geos;
                #   pdal = pdal;
                #   proj = proj;
                # };
              in
              pkgs.callPackage ./pkgs/qgis {
                qgis-unwrapped = pkgs.libsForQt5.callPackage ./pkgs/qgis/unwrapped.nix {
                  inherit geos gdal libspatialindex libspatialite pdal proj;

                  python3 = qgis-python;
                  # grass = geonix-grass;
                  withGrass = false;
                };
              };

            qgis-ltr =
              let
                qgis-python =
                  let
                    packageOverrides = final: prev: {
                      pyqt5 = prev.pyqt5.override { withLocation = true; };
                      owslib = python-owslib;
                      gdal = gdal;
                    };
                  in
                  pkgs.python3.override { inherit packageOverrides; self = qgis-python; };

                # geonix-grass = pkgs.grass.override {
                #   gdal = gdal;
                #   geos = geos;
                #   pdal = pdal;
                #   proj = proj;
                # };
              in
              pkgs.callPackage ./pkgs/qgis/ltr.nix {
                qgis-ltr-unwrapped = pkgs.libsForQt5.callPackage ./pkgs/qgis/unwrapped-ltr.nix {
                  inherit geos gdal libspatialindex libspatialite pdal proj;

                  python3 = qgis-python;
                  # grass = geonix-grass;
                  withGrass = false;
                };
              };


            # all-packages is built in CI. Add all packages here !
            all-packages = pkgs.symlinkJoin {
              name = "all-packages";
              paths = with self.packages; [
                gdal
                geos
                libgeotiff
                libspatialindex
                libspatialite
                pdal
                postgis
                proj
                python-fiona
                python-gdal
                python-geopandas
                python-owslib
                python-pyproj
                python-rasterio
                python-shapely
              ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ qgis qgis-ltr ];
            };

          };


          #
          ### APPS ##
          #

          apps = rec {

            qgis = {
              type = "app";
              program = "${self.packages.${system}.qgis}/bin/qgis";
            };

            qgis-ltr = {
              type = "app";
              program = "${self.packages.${system}.qgis-ltr}/bin/qgis";
            };

            default = qgis;

          };


          #
          ### SHELLS ###
          #

          devShells = {

            default =
              let
                py = pkgs.python3;

                geonixPython = py.withPackages (p: with self.packages.${system}; [
                  python-fiona
                  python-gdal
                  python-geopandas
                  python-owslib
                  python-pyproj
                  python-rasterio
                  python-shapely
                ]);

              in
              pkgs.mkShellNoCC {
                packages = with self.packages.${system}; [
                  gdal
                  geos
                  pdal
                  proj
                  geonixPython
                ];
              };

            postgis =
              let
                pg = pkgs.postgresql;

                geonixPostgis = pg.withPackages (p: with self.packages.${system}; [ postgis ]);

                postgresInitdbArgs = [ "--locale=C" "--encoding=UTF8" ];

                postgresConf =
                  pkgs.writeText "postgresql.conf"
                    ''
                      # Geonix custom settings
                      log_connections = on
                      log_directory = 'pg_log'
                      log_disconnections = on
                      log_duration = on
                      log_filename = 'postgresql.log'
                      log_min_duration_statement = 100  # ms
                      log_min_error_statement = error
                      log_min_messages = warning
                      log_statement = 'all'
                      log_timezone = 'UTC'
                      logging_collector = on
                    '';

              in
              pkgs.mkShellNoCC {
                packages = [ geonixPostgis ];

                shellHook = ''
                  # Initialize DB
                  export PGUSER="postgres"
                  export PGDATA="$(pwd)/.geonix/services/postgres"
                  export PGHOST="$PGDATA"
                  export PGPORT="15432"

                  [ ! -d $PGDATA ] && pg_ctl initdb -o "${pkgs.lib.concatStringsSep " " postgresInitdbArgs} -U $PGUSER" && cat "${postgresConf}" >> $PGDATA/postgresql.conf
                  [ ! -f $PGDATA/postmaster.pid ] && pg_ctl -o "-p $PGPORT -k $PGDATA" start

                  echo -e "\n### USAGE:"
                  echo "PostgreSQL: ${pg.version}"
                  echo "PostGIS:    ${self.packages.${system}.postgis.version}"
                  echo "PGDATA:     $PGDATA"
                  echo
                  echo "Connection: psql"
                  echo "Logs:       tail -f \$PGDATA/pg_log/postgresql.log"
                  echo "Stop DB:    pg_ctl stop"
                  echo
                '';
              };

            nixDev = pkgs.mkShellNoCC {

              packages = with pkgs; [
                nix-prefetch-git
                nix-prefetch-github
                jq
              ];
            };
          };

        }) // {


      #
      ### OVERLAYS ###
      #

      overlays = {

        x86_64-linux = _: _: {
          geonix = self.packages.x86_64-linux;
        };

        x86_64-darwin = _: _: {
          geonix = self.packages.x86_64-darwin;
        };

      };


      #
      ### TEMPLATES ###
      #

      templates = import ./templates.nix;

    };
}
