{
  description = "Custom images tests";

  nixConfig.extra-substituters = [ "https://geonix.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "geonix.cachix.org-1:iyhIXkDLYLXbMhL3X3qOLBtRF8HEyAbhPXjjPeYsCl0=" ];

  nixConfig.bash-prompt = "\\[\\033[1m\\][geonix]\\[\\033\[m\\]\\040\\w >\\040";

  inputs.geonix.url = "path:../../";
  inputs.nixpkgs.follows = "geonix/nixpkgs";

  inputs.utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, geonix, utils }:

    utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let

        pkgs = geonix.lib.getPackages {
          inherit system nixpkgs geonix;

          pythonVersion = pythonVersion;
          postgresqlVersion = postgresqlVersion;

          # overridesFile = ./overrides.nix;
        };

        pythonVersion = "python3";
        postgresqlVersion = "postgresql";

      in
      {

        packages = {
          postgresqlImage = pkgs.geonix.geonix-postgresql-image;
          pythonImage = pkgs.geonix.geonix-python-image;
        };


        devShells = rec {
          ci = pkgs.nixpkgs.mkShellNoCC {
            packages = [
              pkgs.geonix.geonixcli
            ];
          };

          default = ci;
        };
      });
}
