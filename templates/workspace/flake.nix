{
  description = "Geospatial workspace";

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


        # Choose PostgreSQL version here.
        # Supported versions:
        # * postgresql    - default PostgreSQL version
        # * postgresql_11 - PostgreSQL 11
        # * postgresql_12 - PostgreSQL 12
        # * postgresql_13 - PostgreSQL 13
        # * postgresql_14 - PostgreSQL 14
        # * postgresql_15 - PostgreSQL 15
        postgresqlVersion = "postgresql";

        # PostgreSQL init DB arguments
        # See: https://www.postgresql.org/docs/current/app-initdb.html
        postgresqlInitdbArgs = [ "--locale=C" "--encoding=UTF8" ];

        # Add more PostgreSQL extensions
        extraPostgresqlPackages = [
          # pkgs.nixpkgs.${postgresqlVersion}.pkgs.pgrouting
        ];

      in
      {

        #
        ### APPS ##
        #

        apps = rec {

          qgis = {
            type = "app";
            program = "${pkgs.geonix.qgis}/bin/qgis";
          };

          qgis-ltr = {
            type = "app";
            program = "${pkgs.geonix.qgis-ltr}/bin/qgis";
          };

          default = qgis;
        };


        #
        ### SHELLS ###
        #

        devShells = rec {

          # PostgreSQL shell
          postgresql = geonix.lib.mkPostgresqlShell {
            inherit pkgs;
            version = postgresqlVersion;
            initdbArgs = postgresqlInitdbArgs;
            extraPostgresqlPackages = extraPostgresqlPackages;
          };

          # PSQL shell
          psql = geonix.lib.mkPostgresqlClientShell {
            inherit pkgs;
            version = postgresqlVersion;
          };

          # pgAdmin shell
          pgadmin = geonix.lib.mkPgAdminShell {
            inherit pkgs;
          };

          # Main workspace shell
          cli = pkgs.nixpkgs.mkShellNoCC {

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

          default = cli;
        };
      });
}
