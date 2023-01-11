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

          # Run 'geonix override' command to get overrides.nix template file and
          # enable following line to start customizing Geonix packages.

          # overridesFile = ./overrides.nix;
        };

        py = pkgs.nixpkgs.python3;

        pythonPackage = py.withPackages (p: [

          # Geonix Python packages
          pkgs.geonix.python-fiona
          pkgs.geonix.python-gdal
          pkgs.geonix.python-geopandas
          pkgs.geonix.python-owslib
          pkgs.geonix.python-pyproj
          pkgs.geonix.python-rasterio
          pkgs.geonix.python-psycopg
          pkgs.geonix.python-shapely
        ]);

      in
      {

        #
        ### PACKAGES ###
        #

        packages = utils.lib.filterPackages system rec {

          # PostgreSQL/PostGIS container image provided by Geonix
          postgresImage = pkgs.imgs.geonix-postgresql-image;

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
              pythonPackage

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
