/*

Function:         mkPgAdminShell
Description:      Create pgAdmin shell.

Parameters:
* pkgs:           packages attribute set used to build shell environment. Must
                  be in format as returned by getPackages function.

* port:           pgAdmin port.
                  Default: `15050`.

*/

{ pkgs
, port ? 15050
}:

let
  pgadminServiceDir = ".geonix/services/pgadmin";

  pgadminPort = port;

  pgadminConf =
    pkgs.nixpkgs.writeText "config_local.py"
      ''
        import logging

        DATA_DIR = ""
        SERVER_MODE = False  # force desktop mode behavior

        AZURE_CREDENTIAL_CACHE_DIR = f"{DATA_DIR}/azurecredentialcache"
        CONSOLE_LOG_LEVEL = logging.CRITICAL
        DEFAULT_SERVER_PORT = ${toString pgadminPort}
        ENABLE_PSQL = True
        LOG_FILE = f"{DATA_DIR}/log/pgadmin.log"
        MASTER_PASSWORD_REQUIRED = False
        SESSION_DB_PATH = f"{DATA_DIR}/sessions"
        SQLITE_PATH = f"{DATA_DIR}/pgadmin.db"
        STORAGE_DIR = f"{DATA_DIR}/storage"
      '';

  pgadminServiceStart =
    pkgs.nixpkgs.writeShellScriptBin "service-start"
      ''
        set -euo pipefail

        echo "PGADMIN_SERVICE_DIR: $PGADMIN_SERVICE_DIR"
        mkdir -p $PGADMIN_SERVICE_DIR/config $PGADMIN_SERVICE_DIR/data

        cat ${pgadminConf} \
          | sed "s|DATA_DIR.*=.*|DATA_DIR = '$PGADMIN_SERVICE_DIR/data'|" \
          > $PGADMIN_SERVICE_DIR/config/config_local.py

        PYTHONPATH=$PYTHONPATH:$PGADMIN_SERVICE_DIR/config
        exec pgadmin4
      '';

  pgadminServiceProcfile =
    pkgs.nixpkgs.writeText "service-procfile"
      ''
        pgadmin: ${pgadminServiceStart}/bin/service-start
      '';
in

pkgs.nixpkgs.mkShell {

  buildInputs = [ pkgs.nixpkgs.pgadmin4 pkgs.nixpkgs.honcho ];

  shellHook = ''
    mkdir -p ${pgadminServiceDir}
    export PGADMIN_SERVICE_DIR="$(pwd)/${pgadminServiceDir}"

    honcho -f ${pgadminServiceProcfile} start pgadmin
  '';
}
