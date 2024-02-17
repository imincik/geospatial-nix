{ config, lib, ... }:

let cfg = config.services.foo;

in {
  options = {
    services.foo = {
      enable = lib.mkEnableOption "Test";
    };
  };
  config = lib.mkIf cfg.enable {
    processes.foo.exec = "ping 8.8.8.8";
  };
}