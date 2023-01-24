{
  description = "Custom Geonix packages build";

  nixConfig.extra-substituters = [ "https://geonix.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "geonix.cachix.org-1:iyhIXkDLYLXbMhL3X3qOLBtRF8HEyAbhPXjjPeYsCl0=" ];

  nixConfig.bash-prompt = "\\[\\033[1m\\][geonix]\\[\\033\[m\\]\\040\\w >\\040";

  inputs.geonix.url = "github:imincik/geonix";
  inputs.nixpkgs.follows = "geonix/nixpkgs";

  inputs.utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, geonix, utils }:

    utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
      let

        pkgs = geonix.lib.getPackages {
          inherit system nixpkgs geonix;

          pythonVersion = pythonVersion;
          postgresqlVersion = postgresqlVersion;

          # Run 'geonix override' command to get overrides.nix template file and
          # enable following line to start customizing Geonix packages.

          # overridesFile = ./overrides.nix;
        };

        # Choose Python version here.
        # Supported versions:
        # * python3   - default Python version
        # * python39  - Python 3.9
        # * python310 - Python 3.10
        # * python311 - Python 3.11
        pythonVersion = "python3";

        # Choose PostgreSQL version here.
        # Supported versions:
        # * postgresql    - default PostgreSQL version
        # * postgresql_11 - PostgreSQL 11
        # * postgresql_12 - PostgreSQL 12
        # * postgresql_13 - PostgreSQL 13
        # * postgresql_14 - PostgreSQL 14
        # * postgresql_15 - PostgreSQL 15
        postgresqlVersion = "postgresql";

        pythonEnv = pkgs.nixpkgs.${pythonVersion}.withPackages (p: [
          # Geonix Python packages
          pkgs.geonix."${pythonVersion}-fiona"
          pkgs.geonix."${pythonVersion}-gdal"
          pkgs.geonix."${pythonVersion}-geopandas"
          pkgs.geonix."${pythonVersion}-owslib"
          pkgs.geonix."${pythonVersion}-pyproj"
          pkgs.geonix."${pythonVersion}-rasterio"
          pkgs.geonix."${pythonVersion}-psycopg"
          pkgs.geonix."${pythonVersion}-shapely"
        ]);

      in
      {

        #
        ### PACKAGES ###
        #

        packages = utils.lib.filterPackages system {

          # PostgreSQL/PostGIS container image provided by Geonix
          postgresqlImage = pkgs.nixpkgs.lib.optionals pkgs.nixpkgs.stdenv.isLinux

            pkgs.geonix.geonix-postgresql-image;

          # Python container image provided by Geonix
          pythonImage = pkgs.nixpkgs.lib.optionals pkgs.nixpkgs.stdenv.isLinux

            pkgs.geonix.geonix-python-image;
        };


        #
        ### SHELLS ###
        #

        devShells = rec {

          # Development shell
          dev = pkgs.nixpkgs.mkShellNoCC {

            # List of packages to be present in shell environment
            packages = [
              # Geonix CLI
              pkgs.geonix.geonixcli

              # Python with packages
              pythonEnv

              # Tools
              pkgs.geonix.gdal
              pkgs.geonix.geos
              pkgs.geonix.pdal
              pkgs.geonix.proj

              # Apps
              # pkgs.geonix.qgis
            ];
          };

          default = dev;
        };
      });
}
