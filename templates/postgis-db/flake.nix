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

        # PostgreSQL initdb arguments
        postgresInitdbArgs = [ "--locale=C" "--encoding=UTF8" ];

        # PostgreSQL configuration
        postgresConf =
          pkgs.writeText "postgresql.conf"
            ''
              # Geonix custom configuration
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

        # PgAdmin configuration
        pgAdminConf =
          pkgs.writeText "config_local.py"
            ''
              #!/usr/bin/env python

              DATA_DIR = ""

              SERVER_MODE = False  # force desktop mode behavior
              MASTER_PASSWORD_REQUIRED = False

              AZURE_CREDENTIAL_CACHE_DIR = f"{DATA_DIR}/azurecredentialcache"
              DEFAULT_SERVER_PORT = 15050
              ENABLE_PSQL = True
              LOG_FILE = f"{DATA_DIR}/logs/pgadmin.log"
              SESSION_DB_PATH = f"{DATA_DIR}/sessions"
              SQLITE_PATH = f"{DATA_DIR}/pgadmin.db"
              STORAGE_DIR = f"{DATA_DIR}/storage"
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
            packages = [ geonixPostgis ];  # add pkgs.pgcli package if you like it

            # Database initialization and launch script executed when shell
            # environment is started.
            shellHook = ''
              # Initialize DB
              export PGUSER="postgres"
              export PGDATA="$(pwd)/.geonix/services/postgres"
              export PGHOST="$PGDATA"
              export PGPORT="15432"

              [ ! -d $PGDATA ] && pg_ctl initdb -o "${pkgs.lib.concatStringsSep " " postgresInitdbArgs} -U $PGUSER" && cat "${postgresConf}" >> $PGDATA/postgresql.conf
              [ ! -f $PGDATA/postmaster.pid ] && pg_ctl -o "-p $PGPORT -k $PGDATA" start

              echo -e "\n### USAGE:"
              echo "PostgreSQL:     ${pg.version}"
              echo "PostGIS:        ${pkgs.geonix.postgis.version}"
              echo "PGDATA:         $PGDATA"
              echo "Binaries PATH:  ${pg}/bin"
              echo
              echo "Connection:     psql"
              echo "Logs:           tail -f $PGDATA/pg_log/postgresql.log"
              echo "Stop DB:        pg_ctl stop"
              echo
            '';
          };

          pgAdmin = pkgs.mkShellNoCC {

            # List of packages to be present in shell environment
            packages = [ pkgs.pgadmin4 ];

            shellHook = ''
              DATA_DIR="$(pwd)/.geonix/services/pgadmin"

              mkdir -p $DATA_DIR/config

              cat ${pgAdminConf} \
              | sed "s|DATA_DIR.*=.*|DATA_DIR = '$DATA_DIR'|" \
              > .geonix/services/pgadmin/config/config_local.py

              echo -e "\n### USAGE:"
              echo "PgAdmin:        ${pkgs.pgadmin4.version}"
              echo "DATA_DIR:       $DATA_DIR"
              echo
              echo "URL:            http://127.0.0.1:15050"
              echo "Stop PgAdmin:   [CTRL-C]"
              echo

              PYTHONPATH=$PYTHONPATH:$(pwd)/.geonix/services/pgadmin/config pgadmin4
            '';
          };

          default = postgres;
        };
      });
}
