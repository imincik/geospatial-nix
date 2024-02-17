{
  description = "Geospatial packages repository and environment";

  nixConfig = {
    extra-substituters = [ "https://geonix.cachix.org" ];
    extra-trusted-public-keys = [ "geonix.cachix.org-1:iyhIXkDLYLXbMhL3X3qOLBtRF8HEyAbhPXjjPeYsCl0=" ];

    bash-prompt = "\\[\\033[1m\\][geonix]\\[\\033\[m\\]\\040\\w >\\040";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixgl, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ]
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

        in
        {

          # Each new package must be added to:
          # * flake.nix: packages
          # * flake.nix: all-packages, python-packages.all-packages or postgresql-packages.all-packages
          # * pkgs/geonixcli/nix/overrides.nix
          # * .github/workflows/update-packages.yml: matrix.package

          #
          ### PACKAGES ###
          #

          packages =

            let
              inherit (nixpkgs.lib) forEach genAttrs mapAttrs';
              inherit (nixpkgs.lib.attrsets) mergeAttrsList;

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

              # Function: prefix packages and remove `__toString` attribute
              prefixPackages = packages: prefix:
                builtins.removeAttrs
                  (mapAttrs'
                    (
                      name: value: { name = "${prefix}-" + name; value = value; }
                    )
                    packages
                  )
                  [ "${prefix}-__toString" ];


              geonixcli = pkgs.callPackage ./pkgs/geonixcli { };


              # Core libs
              gdal = pkgs.callPackage ./pkgs/gdal {
                inherit geos libgeotiff libspatialite proj tiledb;
                useJava = false;
              };
              gdal-minimal = pkgs.callPackage ./pkgs/gdal {
                inherit geos libgeotiff libspatialite proj tiledb;
                useMinimalFeatures = true;
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
                inherit gdal libgeotiff tiledb;
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
                  # FIX sip and pyqt5_sip compatibility. See: https://github.com/NixOS/nixpkgs/issues/273561
                  # Remove this fix in NixOS 24.05.
                  pyqt5_sip = pkgs.${python}.pkgs.callPackage ./pkgs/qgis/pyqt5-sip.nix { };
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

                __toString = self: python;
              });


              # Postgresql packages
              postgresql-packages = forAllPostgresqlVersions (postgresql: rec {

                postgis = pkgs.callPackage ./pkgs/postgis/postgis.nix {
                  inherit geos proj;

                  gdalMinimal = gdal-minimal;
                  postgresql = pkgs.${postgresql};
                };

                # all packages (single Postgresql version)
                all-packages = pkgs.symlinkJoin {
                  name = "all-${postgresql}-packages";
                  paths = [
                    postgis
                  ];
                };

                __toString = self: postgresql;
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

              # nixGL
              nixGL = nixgl.packages.${system}.nixGLIntel;

              # all-packages (meta package containing all packages)
              all-packages = pkgs.symlinkJoin {
                name = "all-packages";
                paths = [
                  gdal
                  gdal-minimal
                  geonixcli
                  geos
                  libgeotiff
                  librttopo
                  libspatialindex
                  libspatialite
                  pdal
                  proj

                  tiledb

                  nixGL
                ]

                # Add Python packages in all versions
                ++ forEach (builtins.attrNames python-packages) (v: python-packages.${v}.all-packages)

                # Add Postgresql packages in all versions
                ++ forEach (builtins.attrNames postgresql-packages) (v: postgresql-packages.${v}.all-packages)

                # Add Linux only packages
                ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ grass qgis qgis-ltr ];
              };

            in
            flake-utils.lib.filterPackages system
              {
                inherit

                  # Core libs
                  gdal
                  gdal-minimal
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

                  # Meta packages
                  all-packages

                  # nixGL
                  nixGL;
              }

            # Add Python packages in all versions
            // mergeAttrsList (forEach (builtins.attrValues python-packages) (p: prefixPackages p "${p}"))

            # Add Postgresql packages in all versions
            // mergeAttrsList (forEach (builtins.attrValues postgresql-packages) (p: prefixPackages p "${p}"));


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


        test-qgis = pkgs.nixosTest (import ./tests/nixos/qgis.nix {
          inherit nixpkgs pkgs;
          lib = nixpkgs.lib;
          qgisPackage = self.packages.${system}.qgis;
        });

        test-qgis-ltr = pkgs.nixosTest (import ./tests/nixos/qgis.nix {
          inherit nixpkgs pkgs;
          lib = nixpkgs.lib;
          qgisPackage = self.packages.${system}.qgis-ltr;
        });

        # nixGL
        test-nixgl = pkgs.nixosTest (import ./tests/nixos/nixgl.nix {
          inherit nixpkgs pkgs;
          lib = nixpkgs.lib;
          nixGL = self.packages.${system}.nixGL;
        });

        # TODO: add postgis test

        checks = {

          # package tests
          test-gdal = self.packages.${system}.gdal.tests.gdal;
          test-geos = self.packages.${system}.geos.tests.geos;
          test-pdal = self.packages.${system}.pdal.tests.pdal;
          test-proj = self.packages.${system}.proj.tests.proj;
          test-grass = self.packages.${system}.grass.tests.grass;

          # nixos tests
          test-qgis = self.test-qgis.${system};
          test-qgis-ltr = self.test-qgis-ltr.${system};

          # nixgl
          test-nixgl = self.test-nixgl.${system};
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
      ### LIB ###
      #

      lib = import ./lib { inherit (nixpkgs) lib; };


      #
      ### MODULES ###
      #

      modules = import ./modules { };
    };
}
