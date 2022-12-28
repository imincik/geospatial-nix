{
  description = "Python application";

  nixConfig.extra-substituters = [ "https://geonix.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "geonix.cachix.org-1:iyhIXkDLYLXbMhL3X3qOLBtRF8HEyAbhPXjjPeYsCl0=" ];

  nixConfig.bash-prompt = "\\[\\033[1m\\][geonix]\\[\\033\[m\\]\\040\\w >\\040";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
  inputs.geonix.url = "github:imincik/geonix";
  inputs.utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, geonix, utils }:
    utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ geonix.overlays.default ];
        };

        # Choose your PostgreSQL version here.
        # Supported versions:
        # * postgresql_11
        # * postgresql_12
        # * postgresql_13
        # * postgresql_14
        # * postgresql_15
        pg = pkgs.postgresql;

        geonixPostgis = pg.withPackages (p: with geonix.packages.${system}; [ postgis ]);

        # PostgreSQL initdb arguments
        postgresInitdbArgs = [ "--locale=C" "--encoding=UTF8" ];

        # PostgreSQL configuration
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
      {
        #
        ### SHELLS ###
        #

        devShells = {

          # PostgreSQL database shell
          default = pkgs.mkShellNoCC {

            # list of packages to be present in shell environment
            packages = [ geonixPostgis ];

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
              echo "PostgreSQL: ${pg.version}"
              echo "PostGIS:    ${geonix.packages.${system}.postgis.version}"
              echo "PGDATA:     $PGDATA"
              echo
              echo "Connection: psql"
              echo "Logs:       tail -f \$PGDATA/pg_log/postgresql.log"
              echo "Stop DB:    pg_ctl stop"
              echo
            '';
          };
        };
      });
}
