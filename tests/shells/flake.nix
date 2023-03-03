{
  description = "Shell tests";

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
          postgresqlVersion = postgresqlVersion;

         # overridesFile = ./overrides.nix;
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

        devShells = rec {

          # Dev shell
          dev = geonix.lib.mkDevShell {
            inherit pkgs;
            packages = extraPackages;
            envVariables = { MESSAGE = "OK"; };
            shellHook = ''
              echo $MESSAGE
            '';
          };

          # PostgreSQL shell
          postgresql = geonix.lib.mkPostgresqlShell {
            inherit pkgs;
            version = postgresqlVersion;
            extraPostgresqlPackages = extraPostgresqlPackages;
            initialDatabase = "test";
          };

          # PostgreSQL client shell
          psql = geonix.lib.mkPostgresqlClientShell {
            inherit pkgs;
            postgresqlVersion = postgresqlVersion;
          };

          # pgAdmin shell
          pgadmin = geonix.lib.mkPgAdminShell {
            inherit pkgs;
          };

          # Python shell
          python = geonix.lib.mkPythonDevShell {
            inherit pkgs;
            version = pythonVersion;
            extraPythonPackages = extraPythonPackages;
            extraPackages = extraPackages;
            envVariables = { MESSAGE = "OK"; };
            shellHook = ''
              echo $MESSAGE
            '';
          };

          ci = pkgs.nixpkgs.mkShell {
            buildInputs = [
              pkgs.nixpkgs.netcat-gnu
            ];
          };

        };
      });
}
