{
  description = "Custom packages tests";

  nixConfig.extra-substituters = [ "https://geonix.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "geonix.cachix.org-1:iyhIXkDLYLXbMhL3X3qOLBtRF8HEyAbhPXjjPeYsCl0=" ];

  nixConfig.bash-prompt = "\\[\\033[1m\\][geonix]\\[\\033\[m\\]\\040\\w >\\040";

  inputs.geonix.url = "path:../../";
  inputs.nixpkgs.follows = "geonix/nixpkgs";

  inputs.utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, geonix, utils }:

    utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
      let

        pkgs = geonix.lib.getPackages {
          inherit system nixpkgs geonix;

          pythonVersion = pythonVersion;

          # overridesFile = ./overrides.nix;
        };

        pythonVersion = "python3";
        pythonEnv = pkgs.nixpkgs.${pythonVersion}.withPackages (p: [
          pkgs.geonix."${pythonVersion}-fiona"
        ]);

      in
      {

        devShells = rec {

          dev = pkgs.nixpkgs.mkShell {

            buildInputs = [
              pkgs.geonix.geonixcli
              pythonEnv
              pkgs.geonix.gdal
            ];
          };

          default = dev;
        };
      });
}
