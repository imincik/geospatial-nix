{ config, lib, ... }:

let cfg = config.services.foo2;

in {
  options = {
    services.foo2 = {
      enable = lib.mkEnableOption "Test";
    };
  };
  config = lib.mkIf cfg.enable {
    processes.foo2.exec = "ping 8.8.4.4";
  };
}