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
          pkgs = nixpkgs.legacyPackages.${system};

        in
        {

          # Each new package must be added to:
          # * flake.nix: packages
          # * flake.nix: packages.all-packages or packages.python-packages.all-packages
          # * pkgs/geonixcli/nix/overrides.nix
          # * .github/workflows/update-version.yml: matrix.package

          #
          ### PACKAGES ###
          #

          packages =

            let
              inherit (nixpkgs.lib) mapAttrs';

              pythonVersions = [
                "python3" # default
                "python39"
                "python310"
                "python311"
              ];

              forAllPythonVersions = f: nixpkgs.lib.genAttrs pythonVersions (python: f python);

              postgresqlVersions = [
                "postgresql"
                "postgresql_11"
                "postgresql_12"
                "postgresql_13"
                "postgresql_14"
                "postgresql_15"
              ];

              forAllPostgresqlVersions = f: nixpkgs.lib.genAttrs postgresqlVersions (postgresql: f postgresql);


              geonixcli = pkgs.callPackage ./pkgs/geonixcli { };


              # Core libs
              gdal = pkgs.callPackage ./pkgs/gdal {
                inherit geos libgeotiff libspatialite proj;
              };
              _gdal = gdal;

              geos = pkgs.callPackage ./pkgs/geos { };

              libgeotiff = pkgs.callPackage ./pkgs/libgeotiff {
                inherit proj;
              };

              librttopo = pkgs.callPackage ./pkgs/librttopo {
                inherit geos;
              };

              libspatialindex = pkgs.callPackage ./pkgs/libspatialindex { };

              libspatialite = pkgs.callPackage ./pkgs/libspatialite {
                inherit geos librttopo proj;
              };

              pdal = pkgs.callPackage ./pkgs/pdal {
                inherit gdal libgeotiff;
              };

              proj = pkgs.callPackage ./pkgs/proj { };


              # Python packages
              python-packages = forAllPythonVersions (python: rec {
                fiona = pkgs.${python}.pkgs.callPackage ./pkgs/fiona {
                  inherit gdal;
                };

                gdal = pkgs.${python}.pkgs.toPythonModule (_gdal);

                geopandas = pkgs.${python}.pkgs.callPackage ./pkgs/geopandas {
                  inherit fiona pyproj shapely;
                };

                owslib = pkgs.${python}.pkgs.callPackage ./pkgs/owslib {
                  inherit pyproj;
                };

                psycopg = pkgs.${python}.pkgs.psycopg.override {
                  inherit shapely;
                };

                pyproj = pkgs.${python}.pkgs.callPackage ./pkgs/pyproj {
                  inherit proj shapely;
                };

                pyqt5 = pkgs.${python}.pkgs.pyqt5.override {
                  withLocation = true;
                };

                rasterio = pkgs.${python}.pkgs.callPackage ./pkgs/rasterio {
                  inherit gdal shapely;
                };

                shapely = pkgs.${python}.pkgs.callPackage ./pkgs/shapely {
                  inherit geos;
                };

                # all packages (single Python version)
                all-packages = pkgs.symlinkJoin {
                  name = "all-${python}-packages";
                  paths = [
                    fiona
                    gdal
                    geopandas
                    owslib
                    psycopg
                    pyproj
                    pyqt5
                    rasterio
                    shapely
                  ];
                };
              });


              # Postgresql packages
              postgresql-packages = forAllPostgresqlVersions (postgresql: rec {

                postgis = pkgs.callPackage ./pkgs/postgis/postgis.nix {
                  inherit gdal geos proj;

                  postgresql = pkgs.${postgresql};
                };

                # all packages (single Postgresql version)
                all-packages = pkgs.symlinkJoin {
                  name = "all-${postgresql}-packages";
                  paths = [
                    postgis
                  ];
                };
              });


              # QGIS
              qgis-unwrapped =
                let
                  qgis-python =
                    let
                      packageOverrides = final: prev: {
                        pyqt5 = python-packages.python3.pyqt5;
                        owslib = python-packages.python3.owslib;
                        gdal = python-packages.python3.gdal;
                      };
                    in
                    pkgs.python3.override { inherit packageOverrides; self = qgis-python; };
                in
                pkgs.libsForQt5.callPackage ./pkgs/qgis/unwrapped.nix {
                  inherit geos gdal libspatialindex libspatialite pdal proj;

                  python3 = qgis-python;
                  withGrass = false;
                };

              qgis = pkgs.callPackage ./pkgs/qgis { qgis-unwrapped = qgis-unwrapped; };

              # QGIS-LTR
              qgis-ltr-unwrapped =
                let
                  qgis-python =
                    let
                      packageOverrides = final: prev: {
                        pyqt5 = python-packages.python3.pyqt5;
                        owslib = python-packages.python3.owslib;
                        gdal = python-packages.python3.gdal;
                      };
                    in
                    pkgs.python3.override { inherit packageOverrides; self = qgis-python; };
                in
                pkgs.libsForQt5.callPackage ./pkgs/qgis/unwrapped-ltr.nix {
                  inherit geos gdal libspatialindex libspatialite pdal proj;

                  python3 = qgis-python;
                  withGrass = false;
                };

              qgis-ltr = pkgs.callPackage ./pkgs/qgis/ltr.nix { qgis-ltr-unwrapped = qgis-ltr-unwrapped; };


              # all-packages
              all-packages = pkgs.symlinkJoin {
                name = "all-packages";
                paths = with self.packages; [
                  gdal
                  geonixcli
                  geos
                  libgeotiff
                  librttopo
                  libspatialindex
                  libspatialite
                  pdal
                  proj

                  python-packages.python3.all-packages
                  python-packages.python39.all-packages
                  python-packages.python310.all-packages

                  # TODO: build 3.11 packages as well
                  # python-packages.python311.all-packages

                  postgresql-packages.postgresql.all-packages
                  postgresql-packages.postgresql_11.all-packages
                  postgresql-packages.postgresql_12.all-packages
                  postgresql-packages.postgresql_13.all-packages
                  postgresql-packages.postgresql_14.all-packages
                  postgresql-packages.postgresql_15.all-packages

                ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ qgis qgis-ltr ];
              };


              # Container images
              geonix-base-image = pkgs.callPackage ./imgs/base {
                name = "geonix-base";
                tag = "latest";
                bundleNixpkgs = true;
                channelName = "nixpkgs";
                channelURL = "https://nixos.org/channels/nixos-22.11";
                nixConf = { experimental-features = "nix-command flakes"; };
              };

              geonix-postgresql-image = pkgs.callPackage ./imgs/postgres {
                postgis = postgresql-packages.postgresql.postgis;
              };

              geonix-python-image = pkgs.callPackage ./imgs/python {
                python3-fiona = python-packages.python3.fiona;
                python3-gdal = python-packages.python3.gdal;
                python3-geopandas = python-packages.python3.geopandas;
                python3-owslib = python-packages.python3.owslib;
                python3-pyproj = python-packages.python3.pyproj;
                python3-rasterio = python-packages.python3.rasterio;
                python3-shapely = python-packages.python3.shapely;
              };

            in
            flake-utils.lib.filterPackages system
              {
                inherit

                  # Core libs
                  gdal
                  geonixcli
                  geos
                  libgeotiff
                  librttopo
                  libspatialindex
                  libspatialite
                  pdal
                  proj
                  qgis
                  qgis-unwrapped
                  qgis-ltr
                  qgis-ltr-unwrapped

                  # Container images
                  geonix-base-image
                  geonix-postgresql-image
                  geonix-python-image

                  # Meta packages
                  all-packages;
              }

            # Add Python packages in all versions
            // mapAttrs' (name: value: { name = "python3-" + name; value = value; }) python-packages.python3
            // mapAttrs' (name: value: { name = "python39-" + name; value = value; }) python-packages.python39
            // mapAttrs' (name: value: { name = "python310-" + name; value = value; }) python-packages.python310
            // mapAttrs' (name: value: { name = "python311-" + name; value = value; }) python-packages.python311

            # Add Postgresql packages in all versions
            // mapAttrs' (name: value: { name = "postgresql-" + name; value = value; }) postgresql-packages.postgresql
            // mapAttrs' (name: value: { name = "postgresql_11-" + name; value = value; }) postgresql-packages.postgresql_11
            // mapAttrs' (name: value: { name = "postgresql_12-" + name; value = value; }) postgresql-packages.postgresql_12
            // mapAttrs' (name: value: { name = "postgresql_13-" + name; value = value; }) postgresql-packages.postgresql_13
            // mapAttrs' (name: value: { name = "postgresql_14-" + name; value = value; }) postgresql-packages.postgresql_14
            // mapAttrs' (name: value: { name = "postgresql_15-" + name; value = value; }) postgresql-packages.postgresql_15;


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

          devShells = rec {

            # CLI shell
            cli =
              let
                py = pkgs.python3;

                pythonPackage = py.withPackages (p: with self.packages.${system}; [
                  python3-fiona
                  python3-gdal
                  python3-geopandas
                  python3-owslib
                  python3-pyproj
                  python3-rasterio
                  python3-shapely
                ]);

              in
              pkgs.mkShellNoCC {
                packages = with self.packages.${system}; [
                  gdal
                  geos
                  pdal
                  proj
                  pythonPackage
                ];
              };

            # PostgreSQL shell
            postgresql =
              let
                pg = pkgs.postgresql;

                postgresPackage = pg.withPackages (p: with self.packages.${system}; [ postgresql-postgis ]);

                postgresServiceDir = ".geonix/services/postgres";

                postgresInitdbArgs = [ "--locale=C" "--encoding=UTF8" ];

                postgresConf =
                  pkgs.writeText "postgresql.conf"
                    ''
                      log_connections = on
                      log_duration = on
                      log_statement = 'all'
                      log_disconnections = on
                      log_destination = 'stderr'
                    '';

                postgresPort = 15432;

                postgresServiceStart =
                  pkgs.writeShellScriptBin "service-start"
                    ''
                      set -euo pipefail

                      echo "POSTGRES_SERVICE_DIR: $POSTGRES_SERVICE_DIR"

                      export PGDATA=$POSTGRES_SERVICE_DIR/data
                      export PGUSER="postgres"
                      export PGHOST="$PGDATA"
                      export PGPORT="${toString postgresPort}"

                      if [ ! -d $PGDATA ]; then
                        pg_ctl initdb -o "${pkgs.lib.concatStringsSep " " postgresInitdbArgs} -U $PGUSER"
                        cat "${postgresConf}" >> $PGDATA/postgresql.conf

                        echo -e "\nPostgreSQL init process complete. Ready for start up.\n"
                      fi

                      exec ${postgresPackage}/bin/postgres -p $PGPORT -k $PGDATA
                    '';

                postgresServiceProcfile =
                  pkgs.writeText "service-procfile"
                    ''
                      postgres: ${postgresServiceStart}/bin/service-start
                    '';
              in
              pkgs.mkShellNoCC {
                packages = [ postgresPackage pkgs.honcho ];

                shellHook = ''
                  mkdir -p ${postgresServiceDir}
                  export POSTGRES_SERVICE_DIR="$(pwd)/${postgresServiceDir}"

                  honcho -f ${postgresServiceProcfile} start postgres
                '';
              };

            # psql shell
            psql =
              let
                postgresServiceDir = ".geonix/services/postgres";
                postgresPort = 15432;
              in
              pkgs.mkShellNoCC {

                packages = [ pkgs.postgresql pkgs.pgcli ]; # add pkgs.pgcli here if you like it

                shellHook = ''
                  export POSTGRES_SERVICE_DIR="$(pwd)/${postgresServiceDir}"

                  export PGDATA=$POSTGRES_SERVICE_DIR/data
                  export PGUSER="postgres"
                  export PGHOST="$PGDATA"
                  export PGPORT="${toString postgresPort}"
                '';
              };

            # PgAdmin shell
            pgadmin =
              let
                pgAdminServiceDir = ".geonix/services/pgadmin";

                pgAdminConf =
                  pkgs.writeText "config_local.py"
                    ''
                      import logging

                      DATA_DIR = ""
                      SERVER_MODE = False  # force desktop mode behavior

                      AZURE_CREDENTIAL_CACHE_DIR = f"{DATA_DIR}/azurecredentialcache"
                      CONSOLE_LOG_LEVEL = logging.CRITICAL
                      DEFAULT_SERVER_PORT = ${toString pgAdminPort}
                      ENABLE_PSQL = True
                      LOG_FILE = f"{DATA_DIR}/log/pgadmin.log"
                      MASTER_PASSWORD_REQUIRED = False
                      SESSION_DB_PATH = f"{DATA_DIR}/sessions"
                      SQLITE_PATH = f"{DATA_DIR}/pgadmin.db"
                      STORAGE_DIR = f"{DATA_DIR}/storage"
                    '';

                pgAdminPort = 15050;

                pgAdminServiceStart =
                  pkgs.writeShellScriptBin "service-start"
                    ''
                      set -euo pipefail

                      echo "PGADMIN_SERVICE_DIR: $PGADMIN_SERVICE_DIR"
                      mkdir -p $PGADMIN_SERVICE_DIR/config $PGADMIN_SERVICE_DIR/data

                      cat ${pgAdminConf} \
                        | sed "s|DATA_DIR.*=.*|DATA_DIR = '$PGADMIN_SERVICE_DIR/data'|" \
                        > $PGADMIN_SERVICE_DIR/config/config_local.py

                      PYTHONPATH=$PYTHONPATH:$PGADMIN_SERVICE_DIR/config
                      exec pgadmin4
                    '';

                pgAdminServiceProcfile =
                  pkgs.writeText "service-procfile"
                    ''
                      pgadmin: ${pgAdminServiceStart}/bin/service-start
                    '';
              in
              pkgs.mkShellNoCC {
                packages = [ pkgs.pgadmin4 pkgs.honcho ];

                shellHook = ''
                  mkdir -p ${pgAdminServiceDir}
                  export PGADMIN_SERVICE_DIR="$(pwd)/${pgAdminServiceDir}"

                  honcho -f ${pgAdminServiceProcfile} start pgadmin
                '';
              };

            # NIX dev shell
            dev = pkgs.mkShellNoCC {

              packages = with pkgs; [
                nix-prefetch-git
                nix-prefetch-github
                jq
              ];
            };

            default = cli;
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


      #
      ### LIB ###
      #

      lib = import ./lib { inherit (nixpkgs) lib; };

    };
}
