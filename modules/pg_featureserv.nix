{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.pg_featureserv;

  toml = pkgs.formats.toml { };
  defaultConfig = {
    # TODO: read default configuration from config file provided by package
    Server.AssetsPath = "${cfg.package}/share/assets";
    Website.BasemapUrl = "http://tile.openstreetmap.org/{z}/{x}/{y}.png";
  };
  configFile =
    if cfg.settings != { } then
      toml.generate "pg_featureserv.toml" (recursiveUpdate defaultConfig cfg.settings)
    else "${cfg.package}/share/config/pg_featureserv.toml";

  startScript = pkgs.writeShellScriptBin "start-pg_featureserv" ''
    set -euo pipefail

    until ${config.services.postgres.package}/bin/pg_isready -h "''${PGDATA:-unknown}"; do
      echo "Waiting for postgres service to start ..."
      sleep 1
    done

    ${cfg.package}/bin/pg_featureserv --config ${configFile}
  '';
in
{
  options.services.pg_featureserv = {
    enable = mkEnableOption "pg_featureserv service";

    package = mkOption {
      type = types.package;
      description = "Which pg_featureserv package to use.";
      default = pkgs.pg_featureserv;
      defaultText = literalExpression "pkgs.pg_featureserv";
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
        pg_featureserv configuration. Refer to
        <https://github.com/CrunchyData/pg_featureserv/blob/master/config/pg_featureserv.toml.example>
        for an example.
      '';
      example = lib.literalExpression ''
        {
          Server.HttpPort = 9001;
          Paging.LimitMax = 1000;
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

    processes.pg_featureserv = {
      exec = "${startScript}/bin/start-pg_featureserv";
    };
  };
}
