{
  description = "Geonix - geospatial environment for Nix";

  nixConfig.extra-substituters = [ "https://geonix.cachix.org" ];
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
          python-fiona = pkgs.python3.pkgs.callPackage ./pkgs/fiona {
            inherit gdal;
          };

          python-gdal = pkgs.python3.pkgs.toPythonModule (gdal.override {
            inherit geos libgeotiff libspatialite proj;
          });

          python-geopandas = pkgs.python3.pkgs.callPackage ./pkgs/geopandas {
            fiona = python-fiona;
            pyproj = python-pyproj;
            shapely = python-shapely;
          };

          python-rasterio = pkgs.python3.pkgs.callPackage ./pkgs/rasterio {
            inherit gdal;
            shapely = python-shapely;
          };

          python-shapely = pkgs.python3.pkgs.callPackage ./pkgs/shapely {
            inherit geos;
          };

          python-pyproj = pkgs.python3.pkgs.callPackage ./pkgs/pyproj {
            inherit proj;
            shapely = python-shapely;
          };


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
              libspatialindex
              libspatialite
              pdal
              proj
              python-fiona
              python-gdal
              python-geopandas
              python-pyproj
              python-rasterio
              python-shapely
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
      ### OVERLAYS ###
      #
      #
      # TODO: extend overlays for all supported systems
      overlays.default = final: prev: {
        gdal = self.packages.x86_64-linux.gdal;
        geos = self.packages.x86_64-linux.geos;
        libgeotiff = self.packages.x86_64-linux.libgeotiff;
        libspatialindex = self.packages.x86_64-linux.libspatialindex;
        libspatialite = self.packages.x86_64-linux.libspatialite;
        pdal = self.packages.x86_64-linux.pdal;
        proj = self.packages.x86_64-linux.proj;
        python-gdal = self.packages.x86_64-linux.python-gdal;
        python-pyproj = self.packages.x86_64-linux.python-pyproj;
        qgis = self.packages.x86_64-linux.qgis;
        qgis-ltr = self.packages.x86_64-linux.qgis-ltr;
      };


      #
      ### SHELLS ###
      #
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = { permittedInsecurePackages = insecurePackages; };
            overlays = [ self.overlays.default ];
          };

        in
        {
          default =
            let
              py = pkgs.python3;

              geonix-python = py.withPackages (p: with self.packages.${system}; [
                python-gdal
                python-pyproj
                python-fiona
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

      # formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    };
}
