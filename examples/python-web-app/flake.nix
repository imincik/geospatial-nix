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

          # Run 'geonix override' command to get overrides.nix template file and
          # enable following line to start customizing Geonix packages.

          # overridesFile = ./overrides.nix;

          # Python and PostgreSQL versions to use for overrided packages.
          # pythonVersion = "python3";
          # postgresqlVersion = "postgresql";
        };

        geonixConfig = import ./geonix.nix { inherit pkgs geonix; };

      in
      {
        packages =
          if builtins.hasAttr "packages" geonixConfig
          then utils.lib.filterPackages system geonixConfig.packages
          else { };

        devShells =
          if builtins.hasAttr "shells" geonixConfig
          then geonixConfig.shells
          else { };
      }
    );
}
