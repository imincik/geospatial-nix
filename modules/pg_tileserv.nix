{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.pg_tileserv;

  toml = pkgs.formats.toml { };
  defaultConfig = {
    # TODO: read default configuration from config file provided by package
    AssetsPath = "${cfg.package}/share/assets";
  };
  configFile =
    if cfg.settings != { } then
      toml.generate "pg_tileserv.toml" (recursiveUpdate defaultConfig cfg.settings)
    else "${cfg.package}/share/config/pg_tileserv.toml";

  startScript = pkgs.writeShellScriptBin "start-pg_tileserv" ''
    set -euo pipefail

    until ${config.services.postgres.package}/bin/pg_isready -h "''${PGDATA:-unknown}"; do
      echo "Waiting for postgres service to start ..."
      sleep 1
    done

    ${cfg.package}/bin/pg_tileserv --config ${configFile}
  '';
in
{
  options.services.pg_tileserv = {
    enable = mkEnableOption "pg_tileserv service";

    package = mkOption {
      type = types.package;
      description = "Which pg_tileserv package to use.";
      default = pkgs.pg_tileserv;
      defaultText = literalExpression "pkgs.pg_tileserv";
    };

    postgres = {
      host = mkOption {
        type = with types; nullOr str;
        description = "PostgreSQL database host.";
        default = config.env.PGHOST;
      };
      port = mkOption {
        type = types.int;
        description = "PostgreSQL database port.";
        default = config.services.postgres.port;
      };
      database = mkOption {
        type = types.str;
        description = "PostgreSQL database name.";
        default = "postgres";
      };
    };

    settings = lib.mkOption {
      type = with types; attrs;
      default = { };
      description = ''
        pg_tileserv configuration. Refer to
        <https://github.com/CrunchyData/pg_tileserv/blob/master/config/pg_tileserv.toml.example>
        for an example.
      '';
      example = lib.literalExpression ''
        {
          CoordinateSystem = {
            SRID = 3857;
            Xmin = "-20037508.3427892";
            Ymin = "-20037508.3427892";
            Xmax = "20037508.3427892";
            Ymax = "20037508.3427892";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    env.DATABASE_URL =
      let
        host = "host=${cfg.postgres.host}";
        database = "database=${cfg.postgres.database}";
        port = "port=${builtins.toString cfg.postgres.port}";
      in
      concatStringsSep " " [ host port database ];

    processes.pg_tileserv = {
      exec = "${startScript}/bin/start-pg_tileserv";
    };
  };
}
