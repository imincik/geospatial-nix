{
  description = "Geospatial NIX";

  nixConfig = {
    extra-substituters = [
      "https://geonix.cachix.org"
      "https://devenv.cachix.org"
    ];
    extra-trusted-public-keys = [
      "geonix.cachix.org-1:iyhIXkDLYLXbMhL3X3qOLBtRF8HEyAbhPXjjPeYsCl0="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
    bash-prompt = "\\[\\033[1m\\][geonix]\\[\\033\[m\\]\\040\\w >\\040";
  };

  inputs = {
    geonix.url = "github:imincik/geonix";
    nixpkgs.follows = "geonix/nixpkgs";
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "geonix/nixpkgs";
    };
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "geonix/nixpkgs";
    };
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      imports = [
        inputs.devenv.flakeModule
      ];

      systems = [ "x86_64-linux" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {

        devenv.shells.default = {
          imports = [
            ./geonix.nix
          ];
        };
      };

      flake = { };
    };
}
