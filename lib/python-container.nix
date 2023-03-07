/*

Function:         mkPythonContainer
Description:      Create OCI compatible Python container image.

Parameters:
* pkgs:           set of packages used to build shell environment. Must
                  be in format as returned by getPackages function.

* name:           container name.
                  Example: `my-container`. Default: `geonix-python`.

* tag:            container tag.
                  Example: `test`. Default: `latest`.

* pythonVersion:  Python version.
                  Example: `python310`. Default: `python3`.

* extraPythonPackages:
                  extra Python packages to add to Python environment.
                  Example: `pkgs.geonix.python3-fiona`. Default: `[]`.

* extraPackages:
                  extra non-Python packages to install in container.
                  Example: `pkgs.nixpkgs.tig`. Default: `[]`.

*/

{ pkgs
, name ? "geonix-python"
, tag ? "latest"
, pythonVersion ? "python3"
, extraPythonPackages ? []
, extraPackages ? []
}:

let
  lib = pkgs.nixpkgs.lib;

  python = pkgs.nixpkgs.${pythonVersion}.withPackages (p: extraPythonPackages);

  poetry = pkgs.nixpkgs.poetry.override {
    python = pkgs.nixpkgs.${pythonVersion};
  };

in
pkgs.nixpkgs.dockerTools.buildLayeredImage
  {
    name = name;
    tag = tag;

    maxLayers = 100;

    contents = [

      pkgs.nixpkgs.bash
      pkgs.nixpkgs.coreutils
      pkgs.nixpkgs.fakeNss

      pkgs.nixpkgs.zlib

      poetry
      python

    ] ++ extraPackages;

    extraCommands = ''
      mkdir tmp
      chmod 777 tmp

      mkdir opt
      chmod 755 opt
    '';

    config = {
      Env = [
        "PYTHONPATH=${python}/${python.sitePackages}"
      ];
      Entrypoint = [ "${python}/bin/python" ];
    };

  } // {
  meta = {
    description = "Python OCI compatible container image";
    platforms = lib.platforms.linux;
  };
}
