/*

Function:         mkPostgresqlClientShell
Description:      Create interactive PostgreSQL client shell containing
                  pre-configured connection settings to database running
                  in PostgreSQL shell.

Parameters:
* pkgs:           set of packages used to build shell environment. Must
                  be in format as returned by getPackages function.

* postgresqlVersion:
                  PostgreSQL version.
                  Example: `postgresql_12`. Default: `postgresql`.

* postgresqlPort: PostgreSQL port.
                  Default: `15432`.

* extraPackages:
                  extra packages to install in shell environment.
                  Example: `pkgs.nixpkgs.tig`. Default: `[]`.

*/

{ pkgs
, postgresqlVersion ? "postgresql"
, postgresqlPort ? 15432
, extraPackages ? []
}:

let
  postgresqlServiceDir = ".geonix/services/${postgresqlVersion}";

in
pkgs.nixpkgs.mkShell {

  nativeBuildInputs = [ pkgs.nixpkgs.bashInteractive ];
  buildInputs = [
    pkgs.nixpkgs."${postgresqlVersion}"
    pkgs.geonix."${postgresqlVersion}-postgis"
    pkgs.nixpkgs.pgcli
  ] ++ extraPackages;

  shellHook = ''
    export POSTGRES_SERVICE_DIR="$(pwd)/${postgresqlServiceDir}"

    export PGDATA=$POSTGRES_SERVICE_DIR/data
    export PGUSER="postgres"
    export PGHOST="$PGDATA"
    export PGPORT="${toString postgresqlPort}"
  '';
}
