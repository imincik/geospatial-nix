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
