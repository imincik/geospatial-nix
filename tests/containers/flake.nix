{
  description = "Container tests";

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
        };

        pythonVersion = "python3";
        extraPythonPackages = [ pkgs.geonix."${pythonVersion}-fiona" ];
        extraPackages = [ pkgs.nixpkgs.tig ];

        postgresqlVersion = "postgresql";
        postgresqlInitdbArgs = [ "--locale=C" "--encoding=UTF8" ];
        extraPostgresqlPackages = [
          pkgs.nixpkgs.${postgresqlVersion}.pkgs.pgrouting
        ];
      in
      {

        packages = {

          # Python container
          python = geonix.lib.mkPythonContainer {
            inherit pkgs;
            name = "test-python";
            pythonVersion = pythonVersion;
            extraPythonPackages = extraPythonPackages;
            extraPackages = extraPackages;
          };

          # PostgreSQL container
          postgresql = geonix.lib.mkPostgresqlContainer {
            inherit pkgs;
            name = "test-postgresql";
            postgresqlVersion = postgresqlVersion;
            extraPostgresqlPackages = extraPostgresqlPackages;
            initDatabase = "test";
          };

        };

        devShells = {

          # CI shell
          ci = pkgs.nixpkgs.mkShell {

            buildInputs = [
              pkgs.nixpkgs.postgresql
            ];
          };
        };

      });
}
