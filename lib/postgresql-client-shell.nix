/*

Function:         mkPostgresqlClientShell
Description:      Create PostgreSQL CLI client shell.

Parameters:
* pkgs:           packages attribute set used to build shell environment. Must
                  be in format as returned by getPackages function.

* version:        PostgreSQL version.
                  Example: `postgresql_12`. Default: `postgresql`

* port:           PostgreSQL port.
                  Default: `15432`

*/

{ pkgs
, version ? "postgresql"
, port ? 15432
}:

let
  postgresServiceDir = ".geonix/services/${version}";
  postgresPort = port;
in

pkgs.nixpkgs.mkShellNoCC {

  packages = [ pkgs.nixpkgs.postgresql pkgs.nixpkgs.pgcli ];

  shellHook = ''
    export POSTGRES_SERVICE_DIR="$(pwd)/${postgresServiceDir}"

    export PGDATA=$POSTGRES_SERVICE_DIR/data
    export PGUSER="postgres"
    export PGHOST="$PGDATA"
    export PGPORT="${toString postgresPort}"
  '';
}
