{
  description = "Geonix - geospatial environment for Nix";

  nixConfig.extra-substituters = [ "https://geonix.cachix.org?trusted=1" ];
  nixConfig.extra-trusted-public-keys = [ "geonix.cachix.org-1:iyhIXkDLYLXbMhL3X3qOLBtRF8HEyAbhPXjjPeYsCl0=" ];

  nixConfig.bash-prompt = "[geonix] > ";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";

  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self, nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        # "x86_64-darwin"
        # "aarch64-linux"
        # "aarch64-darwin"
      ];

      defaultSystem = "x86_64-linux";

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      # allow insecure QGIS dependency (QtWebkit)
      insecurePackages = [ "qtwebkit-5.212.0-alpha4" ];

    in
    {
      #
      ### PACKAGES ###
      #
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = { permittedInsecurePackages = insecurePackages; };
          };

        in
        rec {
          geos = pkgs.callPackage ./pkgs/geos { };
          libspatialindex = pkgs.callPackage ./pkgs/libspatialindex { };
          proj = pkgs.callPackage ./pkgs/proj { };

          libgeotiff = pkgs.callPackage ./pkgs/libgeotiff {
            inherit proj;
          };

          libspatialite = pkgs.callPackage ./pkgs/libspatialite {
            inherit geos proj;
          };

          gdal = pkgs.callPackage ./pkgs/gdal {
            inherit geos libgeotiff libspatialite proj;
          };

          pdal = pkgs.callPackage ./pkgs/pdal {
            inherit gdal libgeotiff;
          };


          # Python packages
          python-pyproj = pkgs.python3.pkgs.callPackage ./pkgs/pyproj {
            inherit proj;
          };

          python-gdal = pkgs.python3.pkgs.toPythonModule (pkgs.gdal.override {
            inherit geos libgeotiff libspatialite proj;
          });


          # QGIS
          qgis =
            let
              qgis-python =
                let
                  packageOverrides = self: super: {
                    pyqt5 = super.pyqt5.override { withLocation = true; };
                    owslib = super.owslib.override { pyproj = python-pyproj; };
                    gdal = super.packages.${system}.gdal;
                  };
                in
                pkgs.python3.override { inherit packageOverrides; self = qgis-python; };

              # geonix-grass = pkgs.grass.override {
              #   gdal = gdal;
              #   geos = geos;
              #   pdal = pdal;
              #   proj = proj;
              # };
            in
            pkgs.callPackage ./pkgs/qgis {
              qgis-unwrapped = pkgs.libsForQt5.callPackage ./pkgs/qgis/unwrapped.nix {
                inherit geos gdal libspatialindex libspatialite pdal proj;

                python3 = qgis-python;
                # grass = geonix-grass;
                withGrass = false;
              };
            };

          qgis-ltr =
            let
              qgis-python =
                let
                  packageOverrides = self: super: {
                    pyqt5 = super.pyqt5.override { withLocation = true; };
                    owslib = super.owslib.override { pyproj = python-pyproj; };
                    gdal = super.packages.${system}.gdal;
                  };
                in
                pkgs.python3.override { inherit packageOverrides; self = qgis-python; };

              # geonix-grass = pkgs.grass.override {
              #   gdal = gdal;
              #   geos = geos;
              #   pdal = pdal;
              #   proj = proj;
              # };
            in
            pkgs.callPackage ./pkgs/qgis/ltr.nix {
              qgis-ltr-unwrapped = pkgs.libsForQt5.callPackage ./pkgs/qgis/unwrapped-ltr.nix {
                inherit geos gdal libspatialindex libspatialite pdal proj;

                python3 = qgis-python;
                # grass = geonix-grass;
                withGrass = false;
              };
            };


          # all-packages is built in CI. Add all packages here !
          all-packages = pkgs.symlinkJoin {
            name = "all-packages";
            paths = with self.packages; [
              gdal
              geos
              libgeotiff
              libspatialite
              libspatialite
              pdal
              proj
              python-gdal
              python-pyproj
              qgis
              qgis-ltr
            ];
          };
        });


      #
      ### APPS ##
      #
      apps = forAllSystems (system: rec {
        qgis = {
          type = "app";
          program = "${self.packages.${system}.qgis}/bin/qgis";
        };

        qgis-ltr = {
          type = "app";
          program = "${self.packages.${system}.qgis-ltr}/bin/qgis";
        };

        default = qgis;
      });


      #
      ### SHELLS ###
      #
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = { permittedInsecurePackages = insecurePackages; };

            overlays = [
              (final: prev: {
                gdal = self.packages.${system}.gdal;
                geos = self.packages.${system}.geos;
                pdal = self.packages.${system}.pdal;
                proj = self.packages.${system}.proj;
              })
            ];
          };

        in
        {
          default =
            let
              py = pkgs.python3;

              geonix-python = py.withPackages (p: with p; [

                self.packages.${system}.python-gdal

                (pkgs.python3Packages.fiona.override {
                  gdal = self.packages.${system}.gdal;
                })

                (pkgs.python3Packages.geopandas.override {
                  pyproj = self.packages.${system}.python-pyproj;
                })

                (pkgs.python3Packages.owslib.override {
                  pyproj = self.packages.${system}.python-pyproj;
                })

                (pkgs.python3Packages.rasterio.override {
                  gdal = self.packages.${system}.gdal;
                })

                (pkgs.python3Packages.shapely.override {
                  geos = self.packages.${system}.geos;
                })

                pkgs.python3Packages.ipython
              ]);
            in
            pkgs.mkShellNoCC {
              packages = with self.packages.${system}; [
                gdal
                geos
                pdal
                proj
                qgis
                geonix-python
              ];
            };

          nix-dev = pkgs.mkShellNoCC {
            packages = with pkgs; [
              nix-prefetch-git
              nix-prefetch-github
              jq
            ];
          };
        });


      #
      ### CHECKS ###
      #
      test-qgis =
        let
          pkgs = import nixpkgs {
            inherit defaultSystem;

            system = defaultSystem;
            config = { permittedInsecurePackages = insecurePackages; };
          };

          commonx11 = "${nixpkgs}/nixos/tests/common/x11.nix";

        in
        (
          pkgs.nixosTest (import ./tests/qgis {
            inherit pkgs commonx11;
            qgis = self.packages.${defaultSystem}.qgis;
          })
        );

      checks.${defaultSystem} = {
        test-qgis = self.test-qgis;
      };

      # formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    };
}
