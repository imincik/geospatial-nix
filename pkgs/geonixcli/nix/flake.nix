{
  description = "Simple Geonix configuration";

  nixConfig = {
    extra-substituters = [ "https://geonix.cachix.org" ];
    extra-trusted-public-keys = [ "geonix.cachix.org-1:iyhIXkDLYLXbMhL3X3qOLBtRF8HEyAbhPXjjPeYsCl0=" ];
    bash-prompt = "\\[\\033[1m\\][geonix]\\[\\033\[m\\]\\040\\w >\\040";
  };

  inputs = {
    geonix.url = "github:imincik/geonix";
    nixpkgs.follows = "geonix/nixpkgs";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, geonix, utils }:

    utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
      let

        pkgs = geonix.lib.getPackages {
          inherit system nixpkgs geonix;
        };

        geonixConfig = import ./geonix.nix { inherit pkgs geonix; };

      in
      {
        packages =
          if builtins.hasAttr "packages" geonixConfig
          then geonixConfig.packages
          else { };

        devShells =
          if builtins.hasAttr "shells" geonixConfig
          then geonixConfig.shells
          else { };
      }
    );
}
