/*

  Function:       mkPostgresqlContainer
  Description:    Create OCI compatible PostgreSQL container image.

                  WARNING: This image is suitable only for development purposes.
                  It is configured to allow access without any authentication !

  Parameters:
* pkgs:           set of packages used to build shell environment. Must
                  be in format as returned by getPackages function.

* name:           container name.
                  Example: `my-container`. Default: `geonix-python`.

* tag:            container tag.
                  Example: `test`. Default: `latest`.

* postgresqlVersion:
                  PostgreSQL version.
                  Example: `postgresql_12`. Default: `postgresql`.

* extraPostgresqlPackages:
                  extra PostgreSQL extensions to add. PostGIS extension is
                  always included.
                  Example: `[ pkgs.nixpkgs.postgresql_12.pkgs.pgrouting ]`.
                  Default: `[]`.

* initdbArgs:     PostgreSQL initdb arguments.
                  Default: `[ "--locale=C" "--encoding=UTF8" ]`.

* initDatabase:
                  Name of user database created during first run.
                  Default: `geonix`.

*/

{ pkgs
, name ? "geonix-postgresql"
, tag ? "latest"
, postgresqlVersion ? "postgresql"
, extraPostgresqlPackages ? [ ]
, initdbArgs ? [ "--locale=C" "--encoding=UTF8" ]
, initDatabase ? "geonix"
}:

let
  lib = pkgs.nixpkgs.lib;

  postgresqlServiceDir = ".geonix/services/${postgresqlVersion}";

  postgresql = pkgs.nixpkgs.${postgresqlVersion}.withPackages (p: [
    pkgs.geonix."${postgresqlVersion}-postgis"
  ] ++ extraPostgresqlPackages);

  postgresqlPort = 5432;

  postgresqlConf =
    pkgs.nixpkgs.writeText "postgresql.conf"
      ''
        listen_addresses = '*'
        port = ${toString postgresqlPort}

        log_connections = on
        log_destination = 'stderr'
        log_disconnections = on
        log_duration = on
        log_statement = 'all'
      '';

  entrypoint =
    pkgs.nixpkgs.writeShellScriptBin "entrypoint"
      ''
        set -euo pipefail

        mkdir -p $PGDATA

        if [ ! -f $PGDATA/PG_VERSION ]; then

          # PostgreSQL initdb needs to see PGUSER user (postgres) in the system
          # during initdb phase which doesn't exist when running container as
          # our host system user. Below is the trick providing this illusion.

          uid="$(id -u)"
          gid="$(id -g)"

          NSS_WRAPPER_PASSWD="$(mktemp)"
          NSS_WRAPPER_GROUP="$(mktemp)"

          export LD_PRELOAD=${pkgs.nixpkgs.nss_wrapper}/lib/libnss_wrapper.so NSS_WRAPPER_PASSWD NSS_WRAPPER_GROUP
          printf 'postgres:x:%s:%s:PostgreSQL:%s:/bin/false\n' "$uid" "$gid" "$PGDATA" > "$NSS_WRAPPER_PASSWD"
          printf 'postgres:x:%s:\n' "$gid" > "$NSS_WRAPPER_GROUP"

          # initdb \
          #   --username $PGUSER \
          #   --pgdata $PGDATA \
          #   ${lib.concatStringsSep " " initdbArgs}

          pg_ctl initdb -o "${pkgs.nixpkgs.lib.concatStringsSep " " initdbArgs} -U $PGUSER"

          cat "${postgresqlConf}" >> $PGDATA/postgresql.conf
          echo "host  all  all  0.0.0.0/0  trust" >> $PGDATA/pg_hba.conf

          echo "CREATE DATABASE ${initDatabase};" \
          | ${postgresql}/bin/postgres --single postgres

          echo "CREATE EXTENSION postgis;" \
          | ${postgresql}/bin/postgres --single ${initDatabase}

          # End of PGUSER illusion.
          rm -f "$NSS_WRAPPER_PASSWD" "$NSS_WRAPPER_GROUP"
          unset LD_PRELOAD NSS_WRAPPER_PASSWD NSS_WRAPPER_GROUP

          echo -e "\nPostgreSQL init process complete. Ready for start up.\n"
        fi

        ${postgresql}/bin/"$@"
      '';

in
pkgs.nixpkgs.dockerTools.buildLayeredImage
  {
    name = name;
    tag = tag;

    maxLayers = 100;

    contents = [
      pkgs.nixpkgs.bash
      pkgs.nixpkgs.coreutils
      pkgs.nixpkgs.nss_wrapper

      postgresql
      entrypoint
    ];

    extraCommands = ''
      mkdir data tmp
      chmod 777 data tmp
    '';

    config = {
      Env = [
        "PGDATA=/data/${postgresqlServiceDir}"
        "PGHOST=/data/${postgresqlServiceDir}"
        "PGUSER=postgres"
        "PGPORT=${toString postgresqlPort}"
      ];

      Entrypoint = "${entrypoint}/bin/entrypoint";
      Cmd = [ "postgres" "-k" "/data/${postgresqlServiceDir}" ];
      Stopsignal = "SIGINT";

      Volumes = {
        "/data" = { };
      };

      ExposedPorts = {
        "5432/tcp" = { };
      };
    };
  } // {
  meta = {
    description = "PostgreSQL/PostGIS OCI compatible container image";
    platforms = lib.platforms.linux;
  };
}
