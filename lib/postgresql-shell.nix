/*

Function:         mkPostgresqlShell
Description:      Create PostgreSQL/PostGIS database service shell.

Parameters:
* pkgs:           set of packages used to build shell environment. Must
                  be in format as returned by getPackages function.

* postgresqlVersion:
                  PostgreSQL version.
                  Example: `postgresql_12`. Default: `postgresql`.

* postgresqlPort: PostgreSQL port.
                  Default: `15432`.

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
, postgresqlVersion ? "postgresql"
, postgresqlPort ? 15432
, extraPostgresqlPackages ? []
, initdbArgs ? [ "--locale=C" "--encoding=UTF8" ]
, initDatabase ? "geonix"
}:

let
  postgresqlServiceDir = ".geonix/services/${postgresqlVersion}";

  postgresql = pkgs.nixpkgs.${postgresqlVersion}.withPackages (p: [
    pkgs.geonix."${postgresqlVersion}-postgis"
  ] ++ extraPostgresqlPackages);

  postgresqlConf =
    pkgs.nixpkgs.writeText "postgresql.conf"
      ''
        log_connections = on
        log_duration = on
        log_statement = 'all'
        log_disconnections = on
        log_destination = 'stderr'
      '';

  postgresqlServiceStart =
    pkgs.nixpkgs.writeShellScriptBin "service-start"
      ''
        set -euo pipefail

        echo "POSTGRES_SERVICE_DIR: $POSTGRES_SERVICE_DIR"

        export PGDATA=$POSTGRES_SERVICE_DIR/data
        export PGUSER="postgres"
        export PGHOST="$PGDATA"
        export PGPORT="${toString postgresqlPort}"

        if [ ! -d $PGDATA ]; then
          pg_ctl initdb -o "${pkgs.nixpkgs.lib.concatStringsSep " " initdbArgs} -U $PGUSER"
          cat "${postgresqlConf}" >> $PGDATA/postgresql.conf

          echo "CREATE DATABASE ${initDatabase};" \
          | ${postgresql}/bin/postgres --single postgres

          echo "CREATE EXTENSION postgis;" \
          | ${postgresql}/bin/postgres --single ${initDatabase}

          echo -e "\nPostgreSQL init process complete. Ready for start up.\n"
        fi

        ${postgresql}/bin/postgres -p $PGPORT -k $PGDATA
      '';

  postgresqlServiceProcfile =
    pkgs.nixpkgs.writeText "service-procfile"
      ''
        postgres: ${postgresqlServiceStart}/bin/service-start
      '';
in

pkgs.nixpkgs.mkShell {

  buildInputs = [
    postgresql
    pkgs.nixpkgs.honcho
  ];

  shellHook = ''
    mkdir -p ${postgresqlServiceDir}
    export POSTGRES_SERVICE_DIR="$(pwd)/${postgresqlServiceDir}"

    honcho -f ${postgresqlServiceProcfile} start postgres
  '';
}
