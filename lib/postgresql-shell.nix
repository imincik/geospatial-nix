/*

Function:         mkPostgresqlShell
Description:      Create PostgreSQL/PostGIS database shell.

Parameters:
* pkgs:           packages attribute set used to build shell environment. Must
                  be in format as returned by getPackages function.

* version:        PostgreSQL version.
                  Example: `postgresql_12`. Default: `postgresql`.

* port:           PostgreSQL port.
                  Default: `15432`.

* initdbArgs:     PostgreSQL initdb arguments.
                  Default: `[ "--locale=C" "--encoding=UTF8" ]`.

* extraPackages:  extra PostgreSQL extensions.
                  Example: `[ pkgs.nixpkgs.postgresql_12.pkgs.pgrouting ]`. Default: `[]`.

*/

{ pkgs
, version ? "postgresql"
, port ? 15432
, initdbArgs ? [ "--locale=C" "--encoding=UTF8" ]
, extraPackages ? []
}:

let
  postgresServiceDir = ".geonix/services/${version}";

  postgresPackage = pkgs.nixpkgs.${version}.withPackages (p: [
    pkgs.geonix."${version}-postgis"
  ] ++ extraPackages);

  postgresInitdbArgs = initdbArgs;

  postgresConf =
    pkgs.nixpkgs.writeText "postgresql.conf"
      ''
        log_connections = on
        log_duration = on
        log_statement = 'all'
        log_disconnections = on
        log_destination = 'stderr'
      '';

  postgresPort = port;

  postgresServiceStart =
    pkgs.nixpkgs.writeShellScriptBin "service-start"
      ''
        set -euo pipefail

        echo "POSTGRES_SERVICE_DIR: $POSTGRES_SERVICE_DIR"

        export PGDATA=$POSTGRES_SERVICE_DIR/data
        export PGUSER="postgres"
        export PGHOST="$PGDATA"
        export PGPORT="${toString postgresPort}"

        if [ ! -d $PGDATA ]; then
          pg_ctl initdb -o "${pkgs.nixpkgs.lib.concatStringsSep " " postgresInitdbArgs} -U $PGUSER"
          cat "${postgresConf}" >> $PGDATA/postgresql.conf

          echo -e "\nPostgreSQL init process complete. Ready for start up.\n"
        fi

        exec ${postgresPackage}/bin/postgres -p $PGPORT -k $PGDATA
      '';

  postgresServiceProcfile =
    pkgs.nixpkgs.writeText "service-procfile"
      ''
        postgres: ${postgresServiceStart}/bin/service-start
      '';
in

pkgs.nixpkgs.mkShellNoCC {
  packages = [ postgresPackage pkgs.nixpkgs.honcho ];

  shellHook = ''
    mkdir -p ${postgresServiceDir}
    export POSTGRES_SERVICE_DIR="$(pwd)/${postgresServiceDir}"

    honcho -f ${postgresServiceProcfile} start postgres
  '';
}
