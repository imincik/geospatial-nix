{
  description = "Python application";

  nixConfig.extra-substituters = [ "https://geonix.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "geonix.cachix.org-1:iyhIXkDLYLXbMhL3X3qOLBtRF8HEyAbhPXjjPeYsCl0=" ];

  nixConfig.bash-prompt = "\\[\\033[1m\\][geonix]\\[\\033\[m\\]\\040\\w >\\040";

  inputs.geonix.url = "github:imincik/geonix";
  inputs.nixpkgs.follows = "geonix/nixpkgs";

  inputs.utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, geonix, utils }:
    utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;

          # add Geonix overlay with packages under geonix namespace (pkgs.geonix.<PACKAGE>)
          overlays = [ geonix.overlays.${system} ];
        };

        # Choose your PostgreSQL version here.
        # Supported versions:
        # * postgresql_11
        # * postgresql_12
        # * postgresql_13
        # * postgresql_14
        # * postgresql_15
        pg = pkgs.postgresql;

        geonixPostgis = pg.withPackages (p: [ pkgs.geonix.postgis ]);


        # PostgreSQL configuration
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

        postgresServiceDir = ".geonix/services/postgres";

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
              fi

              exec ${geonixPostgis}/bin/postgres -p $PGPORT -k $PGDATA
            '';

        postgresServiceProcfile =
          pkgs.writeText "service-procfile"
          ''
            postgres: ${postgresServiceStart}/bin/service-start
          '';


        # PgAdmin configuration
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

        pgAdminServiceDir = ".geonix/services/pgadmin";

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
      {

        #
        ### SHELLS ###
        #

        devShells = rec {

          # PostgreSQL database shell
          postgres = pkgs.mkShellNoCC {

            # List of packages to be present in shell environment
            packages = [ geonixPostgis pkgs.honcho ];

            # Database initialization and launch script executed when shell
            # environment is started.
            shellHook = ''
              mkdir -p ${postgresServiceDir}
              export POSTGRES_SERVICE_DIR="$(pwd)/${postgresServiceDir}"

              honcho -f ${postgresServiceProcfile} start postgres
            '';
          };

          # PgAdmin shell
          pgAdmin = pkgs.mkShellNoCC {

            # List of packages to be present in shell environment
            packages = [ pkgs.pgadmin4 pkgs.honcho ];

            shellHook = ''
              mkdir -p ${pgAdminServiceDir}
              export PGADMIN_SERVICE_DIR="$(pwd)/${pgAdminServiceDir}"

              honcho -f ${pgAdminServiceProcfile} start pgadmin
            '';
          };

          # psql shell
          psql = pkgs.mkShellNoCC {

            # List of packages to be present in shell environment
            packages = [ geonixPostgis pkgs.pgcli ];  # add pkgs.pgcli here if you like it

            shellHook = ''
              export POSTGRES_SERVICE_DIR="$(pwd)/${postgresServiceDir}"

              export PGDATA=$POSTGRES_SERVICE_DIR/data
              export PGUSER="postgres"
              export PGHOST="$PGDATA"
              export PGPORT="${toString postgresPort}"

              psql
            '';
          };
          default = postgres;
        };
      });
}
