{
  description = "Geonix - geospatial environment for Nix";

  nixConfig = {
    extra-substituters = [ "https://geonix.cachix.org" ];
    extra-trusted-public-keys = [ "geonix.cachix.org-1:iyhIXkDLYLXbMhL3X3qOLBtRF8HEyAbhPXjjPeYsCl0=" ];

    bash-prompt = "\\[\\033[1m\\][geonix]\\[\\033\[m\\]\\040\\w >\\040";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    flake-utils.url = "github:numtide/flake-utils";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ]
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

        in
        {

          # Each new package must be added to:
          # * flake.nix: packages
          # * flake.nix: packages.all-packages or packages.python-packages.all-packages
          # * pkgs/geonixcli/nix/overrides.nix
          # * .github/workflows/update-packages.yml: matrix.package

          #
          ### PACKAGES ###
          #

          packages =

            let
              inherit (nixpkgs.lib) genAttrs mapAttrs';

              pythonVersions = [
                "python3" # default Python version
                "python310"
                "python311"
              ];
              forAllPythonVersions = f: genAttrs pythonVersions (python: f python);

              postgresqlVersions = [
                "postgresql" # default PostgreSQL version
                "postgresql_12"
                "postgresql_13"
                "postgresql_14"
                "postgresql_15"
              ];
              forAllPostgresqlVersions = f: genAttrs postgresqlVersions (postgresql: f postgresql);


              geonixcli = pkgs.callPackage ./pkgs/geonixcli { };


              # Core libs
              gdal = pkgs.callPackage ./pkgs/gdal {
                inherit geos libgeotiff libspatialite proj tiledb;
              };
              _gdal = gdal;

              geos = pkgs.callPackage ./pkgs/geos { };

              libgeotiff = pkgs.callPackage ./pkgs/libgeotiff {
                inherit proj;
              };

              librttopo = pkgs.callPackage ./pkgs/librttopo {
                inherit geos;
              };

              libspatialindex = pkgs.callPackage ./pkgs/libspatialindex { };

              libspatialite = pkgs.callPackage ./pkgs/libspatialite {
                inherit geos librttopo proj;
              };

              pdal = pkgs.callPackage ./pkgs/pdal {
                inherit gdal libgeotiff;
              };

              proj = pkgs.callPackage ./pkgs/proj { };


              # Python packages
              python-packages = forAllPythonVersions (python: rec {
                fiona = pkgs.${python}.pkgs.callPackage ./pkgs/fiona {
                  inherit gdal;
                };

                gdal = pkgs.${python}.pkgs.toPythonModule (_gdal);

                geopandas = pkgs.${python}.pkgs.callPackage ./pkgs/geopandas {
                  inherit fiona pyproj shapely;
                };

                owslib = pkgs.${python}.pkgs.callPackage ./pkgs/owslib {
                  inherit pyproj;
                };

                psycopg = pkgs.${python}.pkgs.psycopg.override {
                  inherit shapely;
                };

                pyproj = pkgs.${python}.pkgs.callPackage ./pkgs/pyproj {
                  inherit proj shapely;
                };

                pyqt5 = pkgs.${python}.pkgs.pyqt5.override {
                  withLocation = true;
                };

                rasterio = pkgs.${python}.pkgs.callPackage ./pkgs/rasterio {
                  inherit gdal shapely;
                };

                shapely = pkgs.${python}.pkgs.callPackage ./pkgs/shapely {
                  inherit geos;
                };

                # all packages (single Python version)
                all-packages = pkgs.symlinkJoin {
                  name = "all-${python}-packages";
                  paths = [
                    fiona
                    gdal
                    geopandas
                    owslib
                    psycopg
                    pyproj
                    pyqt5
                    rasterio
                    shapely
                  ];
                };
              });


              # Postgresql packages
              postgresql-packages = forAllPostgresqlVersions (postgresql: rec {

                postgis = pkgs.callPackage ./pkgs/postgis/postgis.nix {
                  inherit gdal geos proj;

                  postgresql = pkgs.${postgresql};
                };

                # all packages (single Postgresql version)
                all-packages = pkgs.symlinkJoin {
                  name = "all-${postgresql}-packages";
                  paths = [
                    postgis
                  ];
                };
              });


              # TileDB
              tiledb = pkgs.callPackage ./pkgs/tiledb { };


              # GRASS
              grass = pkgs.callPackage ./pkgs/grass {
                inherit gdal geos pdal proj;
              };


              # QGIS
              qgis-unwrapped =
                let
                  qgis-python =
                    let
                      packageOverrides = final: prev: {
                        pyqt5 = python-packages.python3.pyqt5;
                        owslib = python-packages.python3.owslib;
                        gdal = python-packages.python3.gdal;
                      };
                    in
                    pkgs.python3.override { inherit packageOverrides; self = qgis-python; };
                in
                pkgs.libsForQt5.callPackage ./pkgs/qgis/unwrapped.nix {
                  inherit geos gdal libspatialindex libspatialite pdal proj;

                  python3 = qgis-python;
                  withGrass = false;
                };

              qgis = pkgs.callPackage ./pkgs/qgis { qgis-unwrapped = qgis-unwrapped; };

              # QGIS-LTR
              qgis-ltr-unwrapped =
                let
                  qgis-python =
                    let
                      packageOverrides = final: prev: {
                        pyqt5 = python-packages.python3.pyqt5;
                        owslib = python-packages.python3.owslib;
                        gdal = python-packages.python3.gdal;
                      };
                    in
                    pkgs.python3.override { inherit packageOverrides; self = qgis-python; };
                in
                pkgs.libsForQt5.callPackage ./pkgs/qgis/unwrapped-ltr.nix {
                  inherit geos gdal libspatialindex libspatialite pdal proj;

                  python3 = qgis-python;
                  withGrass = false;
                };

              qgis-ltr = pkgs.callPackage ./pkgs/qgis/ltr.nix { qgis-ltr-unwrapped = qgis-ltr-unwrapped; };


              # all-packages
              all-packages = pkgs.symlinkJoin {
                name = "all-packages";
                paths = [
                  gdal
                  geonixcli
                  geos
                  libgeotiff
                  librttopo
                  libspatialindex
                  libspatialite
                  pdal
                  proj

                  python-packages.python3.all-packages
                  python-packages.python310.all-packages
                  python-packages.python311.all-packages

                  postgresql-packages.postgresql.all-packages
                  postgresql-packages.postgresql_12.all-packages
                  postgresql-packages.postgresql_13.all-packages
                  postgresql-packages.postgresql_14.all-packages
                  postgresql-packages.postgresql_15.all-packages

                  tiledb

                ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ grass qgis qgis-ltr ];
              };


              # Container images
              geonix-base-image = pkgs.callPackage ./imgs/base {
                name = "geonix-base";
                tag = "latest";
                bundleNixpkgs = true;
                channelName = "nixpkgs";
                channelURL = "https://nixos.org/channels/nixos-23.11";
                nixConf = { experimental-features = "nix-command flakes"; };
              };

            in
            flake-utils.lib.filterPackages system
              {
                inherit

                  # Core libs
                  gdal
                  geonixcli
                  geos
                  libgeotiff
                  librttopo
                  libspatialindex
                  libspatialite
                  pdal
                  proj

                  tiledb
  
                  # Applications
                  grass
                  qgis
                  qgis-unwrapped
                  qgis-ltr
                  qgis-ltr-unwrapped

                  # Container images
                  geonix-base-image

                  # Meta packages
                  all-packages;
              }

            # Add Python packages in all versions
            // mapAttrs' (name: value: { name = "python3-" + name; value = value; }) python-packages.python3
            // mapAttrs' (name: value: { name = "python310-" + name; value = value; }) python-packages.python310
            // mapAttrs' (name: value: { name = "python311-" + name; value = value; }) python-packages.python311

            # Add Postgresql packages in all versions
            // mapAttrs' (name: value: { name = "postgresql-" + name; value = value; }) postgresql-packages.postgresql
            // mapAttrs' (name: value: { name = "postgresql_12-" + name; value = value; }) postgresql-packages.postgresql_12
            // mapAttrs' (name: value: { name = "postgresql_13-" + name; value = value; }) postgresql-packages.postgresql_13
            // mapAttrs' (name: value: { name = "postgresql_14-" + name; value = value; }) postgresql-packages.postgresql_14
            // mapAttrs' (name: value: { name = "postgresql_15-" + name; value = value; }) postgresql-packages.postgresql_15;


          #
          ### APPS ##
          #

          apps = rec {

            grass = {
              type = "app";
              program = "${self.packages.${system}.grass}/bin/grass";
            };

            qgis = {
              type = "app";
              program = "${self.packages.${system}.qgis}/bin/qgis";
            };

            qgis-ltr = {
              type = "app";
              program = "${self.packages.${system}.qgis-ltr}/bin/qgis";
            };

            default = qgis;

          };


          #
          ### SHELLS ###
          #

          devShells = rec {

            # CLI shell
            cli =
              let
                py = pkgs.python3;

                pythonPackage = py.withPackages (p: with self.packages.${system}; [
                  python3-fiona
                  python3-gdal
                  python3-geopandas
                  python3-owslib
                  python3-pyproj
                  python3-rasterio
                  python3-shapely
                ]);

              in
              pkgs.mkShell {

                nativeBuildInputs = [ pkgs.bashInteractive ];
                buildInputs = with self.packages.${system}; [
                  gdal
                  geos
                  pdal
                  proj
                  pythonPackage
                ];
              };

            # CI shell
            ci = pkgs.mkShell {

              buildInputs = with pkgs; [
                jq
                nix-prefetch-git
                nix-prefetch-github
                postgresql
              ];
            };

            default = cli;
          };

        }) // {


      #
      ### OVERLAYS ###
      #

      overlays = {

        x86_64-linux = _: _: {
          geonix = self.packages.x86_64-linux;
        };

      };


      #
      ### TEMPLATES ###
      #

      templates = import ./templates.nix;


      #
      ### LIB ###
      #

      lib = import ./lib { inherit (nixpkgs) lib; };

    };
}
