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
          # * flake.nix: python-packages.all-packages or postgresql-packages.all-packages
          # * pkgs/geonixcli/nix/overrides.nix

          #
          ### PACKAGES ###
          #


          
          # # default.nix
          # let
          #   python-packages = forAllPythonVersions (python: (lib.makeScope final.newScope (final: {
          #     inherit python;
          #     pythonPackages = python.pkgs;

          #     fiona = final.callPackage ./fiona {};
          #     # ...
          #   })));
          # in

          # # fiona.nix
          # { pythonPackages, geos }:

          # pythonPackages.buildPythonApplication {

          # }


          
          packages =

            let
              inherit (nixpkgs.lib) forEach genAttrs makeScope mapAttrs';
              inherit (nixpkgs.lib.attrsets) attrValues filterAttrs mergeAttrsList;

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


              geopkgs = makeScope pkgs.newScope (final: {
                geonixcli = final.callPackage ./pkgs/geonixcli { };


                # Core libs
                gdal = final.callPackage ./pkgs/gdal {
                  # inherit geos libgeotiff libspatialite proj tiledb;
                  useJava = false;
                };
                gdal-minimal = final.callPackage ./pkgs/gdal {
                  # inherit geos libgeotiff libspatialite proj tiledb;
                  useMinimalFeatures = true;
                };
                _gdal = final.gdal;

                geos = final.callPackage ./pkgs/geos { };

                libgeotiff = final.callPackage ./pkgs/libgeotiff {
                  # inherit proj;
                };

                librttopo = final.callPackage ./pkgs/librttopo {
                  # inherit geos;
                };

                libspatialindex = final.callPackage ./pkgs/libspatialindex { };

                libspatialite = final.callPackage ./pkgs/libspatialite {
                  # inherit geos librttopo proj;
                };

                pdal = final.callPackage ./pkgs/pdal {
                  # inherit gdal libgeotiff proj tiledb;
                };

                proj = final.callPackage ./pkgs/proj { };


                # Python packages
                python-packages = forAllPythonVersions (python: (makeScope pkgs.${python}.pkgs.newScope (pyFinal: {
                  nonPythonFinal = final;

                  fiona = pyFinal.callPackage ./pkgs/fiona {
                    # inherit gdal;
                  };

                  # gdal = pkgs.${python}.pkgs.toPythonModule (final._gdal);

                  geopandas = pyFinal.callPackage ./pkgs/geopandas {
                    # inherit fiona pyproj shapely;
                  };

                  owslib = pyFinal.callPackage ./pkgs/owslib {
                    # inherit pyproj;
                  };

                  psycopg = pyFinal.psycopg.override {
                    # inherit shapely;
                  };

                  pyproj = pyFinal.callPackage ./pkgs/pyproj {
                    # inherit proj shapely;
                  };

                  pyqt5 = pyFinal.pyqt5.override {
                    # FIX sip and pyqt5_sip compatibility. See: https://github.com/NixOS/nixpkgs/issues/273561
                    # Remove this fix in NixOS 24.05.
                    pyqt5_sip = final.callPackage ./pkgs/qgis/pyqt5-sip.nix { };
                    withLocation = true;
                    withSerialPort = true;
                  };

                  rasterio = pyFinal.callPackage ./pkgs/rasterio {
                    # inherit gdal shapely;
                  };

                  shapely = pyFinal.callPackage ./pkgs/shapely {
                    # inherit geos;
                  };

                  # # all packages (single Python version)
                  # all-packages = pkgs.symlinkJoin {
                  #   name = "all-${python}-packages";
                  #   paths = [
                  #     pyFinal.fiona
                  #     # pyFinal.gdal
                  #     pyFinal.geopandas
                  #     pyFinal.owslib
                  #     pyFinal.psycopg
                  #     pyFinal.pyproj
                  #     pyFinal.pyqt5
                  #     pyFinal.rasterio
                  #     pyFinal.shapely
                  #   ];
                  # };

                  __toString = self: python;
                })));


                # Postgresql packages
                postgresql-packages = forAllPostgresqlVersions (postgresql: rec {

                  postgis = final.callPackage ./pkgs/postgis/postgis.nix {
                    # inherit geos proj;

                    gdalMinimal = final.gdal-minimal;
                    postgresql = pkgs.${postgresql};
                  };

                  # # all packages (single Postgresql version)
                  # all-packages = pkgs.symlinkJoin {
                  #   name = "all-${postgresql}-packages";
                  #   paths = [
                  #     postgis
                  #   ];
                  # };

                  __toString = self: postgresql;
                });


                # PG_Featureserv
                pg_featureserv = final.callPackage ./pkgs/pg_featureserv { };

                # PG_Tileserv
                pg_tileserv = final.callPackage ./pkgs/pg_tileserv { };

                # TileDB
                tiledb = final.callPackage ./pkgs/tiledb { };


                # GRASS
                grass = final.callPackage ./pkgs/grass {
                  # inherit gdal geos pdal proj;
                };


                # QGIS
                qgis-unwrapped =
                  let
                    qgis-python =
                      let
                        packageOverrides = final: prev: {
                          # pyqt5 = final.python-packages.python3.pyqt5;
                          # owslib = final.python-packages.python3.owslib;
                          # gdal = final.python-packages.python3.gdal;
                        };
                      in
                      pkgs.python3.override { inherit packageOverrides; self = qgis-python; };
                  in
                  pkgs.libsForQt5.callPackage ./pkgs/qgis/unwrapped.nix {
                    # inherit geos gdal libspatialindex libspatialite pdal proj;

                    python3 = qgis-python;
                    withGrass = false;
                  };

                qgis = final.callPackage ./pkgs/qgis { qgis-unwrapped = final.qgis-unwrapped; };

                # QGIS-LTR
                qgis-ltr-unwrapped =
                  let
                    qgis-python =
                      let
                        packageOverrides = localFinal: prev: {
                          pyqt5 = final.python-packages.python3.pyqt5;
                          owslib = final.python-packages.python3.owslib;
                          gdal = final.python-packages.python3.gdal;
                        };
                      in
                      pkgs.python3.override { inherit packageOverrides; self = qgis-python; };
                  in
                  pkgs.libsForQt5.callPackage ./pkgs/qgis/unwrapped-ltr.nix {
                    # inherit geos gdal libspatialindex libspatialite pdal proj;

                    python3 = qgis-python;
                    withGrass = false;
                  };

                qgis-ltr = final.callPackage ./pkgs/qgis/ltr.nix { qgis-ltr-unwrapped = final.qgis-ltr-unwrapped; };

                # nixGL
                nixGL = nixgl.packages.${system}.nixGLIntel;

                # all-packages (meta package containing all packages)
                # all-packages = pkgs.symlinkJoin {
                #   name = "all-packages";
                #   paths = attrValues (filterAttrs (n: v: n != "all-packages") self.packages.${system});
                # };
              });

            in
            flake-utils.lib.filterPackages system
              {
                inherit (geopkgs)

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

                  pg_featureserv
                  pg_tileserv
                  tiledb

                  # Applications
                  grass
                  qgis
                  qgis-unwrapped
                  qgis-ltr
                  qgis-ltr-unwrapped

                  # Meta packages
                  # all-packages

                  # nixGL
                  nixGL;
              }

            # Add Python packages in all versions
            // mergeAttrsList (forEach (builtins.attrValues geopkgs.python-packages) (p: prefixPackages p "${p}"))

            # Add Postgresql packages in all versions
            // mergeAttrsList (forEach (builtins.attrValues geopkgs.postgresql-packages) (p: prefixPackages p "${p}"));


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


          checks = {
            # package tests
            inherit (self.packages.${system}.gdal.tests)
              ogrinfo-version
              gdalinfo-version
              ogrinfo-format-geopackage
              gdalinfo-format-geotiff
              vector-file
              raster-file;

            inherit (self.packages.${system}.geos.tests) geos;
            inherit (self.packages.${system}.pdal.tests) pdal;
            inherit (self.packages.${system}.proj.tests) proj;
            inherit (self.packages.${system}.grass.tests) grass;

            # nixos tests
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

            test-nixgl = pkgs.nixosTest (import ./tests/nixos/nixgl.nix {
              inherit nixpkgs pkgs;
              lib = nixpkgs.lib;
              nixGL = self.packages.${system}.nixGL;
            });

            # TODO: add postgis test
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
