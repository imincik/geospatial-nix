{ self, system, pkgs }:

rec {

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
}
