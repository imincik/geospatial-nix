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

        postgresqlVersion = "postgresql";
        postgresqlInitdbArgs = [ "--locale=C" "--encoding=UTF8" ];
        extraPostgresqlPackages = [
          pkgs.nixpkgs.${postgresqlVersion}.pkgs.pgrouting
        ];

      in
      {

        devShells = rec {

          # PostgreSQL shell
          postgresql = geonix.lib.mkPostgresqlShell {
            inherit pkgs;
            version = postgresqlVersion;
            extraPackages = extraPostgresqlPackages;
          };

          # PSQL shell
          psql = geonix.lib.mkpsqlShell {
            inherit pkgs;
            version = postgresqlVersion;
          };

          # pgAdmin shell
          pgadmin = geonix.lib.mkpgAdminShell {
            inherit pkgs;
          };

          ci = pkgs.nixpkgs.mkShellNoCC {
            packages = [
              pkgs.nixpkgs.netcat-gnu
            ];
          };

        };
      });
}
