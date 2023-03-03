/*

Function:         mkPythonDevShell
Description:      Create interactive Python development shell containing
                  Python interpreter and Poetry packages manager.
Parameters:
* pkgs:           set of packages used to build shell environment. Must
                  be in format as returned by getPackages function.

* version:        Python version.
                  Example: `python310`. Default: `python3`.

* extraPythonPackages:
                  extra Python packages to add to Python environment.
                  Example: `pkgs.geonix.python3-fiona`. Default: `[]`.

* extraPackages:
                  extra non-Python packages to install in shell environment.
                  Example: `pkgs.nixpkgs.tig`. Default: `[]`.

* envVariables:   list of environment variables to set.
                  Example: `{ MESSAGE = "Hi Pythonista !"; }`. Default: `{}`.

* shellHook:      Bash script to run when shell environment is loaded.
                  Example: `echo $MESSAGE`. Default: `""`.

*/

{ pkgs
, version ? "python3"
, extraPythonPackages ? []
, extraPackages ? []
, envVariables ? {}
, shellHook ? ""
}:

let
  lib = pkgs.nixpkgs.lib;

  python = pkgs.nixpkgs.${version}.withPackages (p: extraPythonPackages);

  poetry = pkgs.nixpkgs.poetry.override {
    python = pkgs.nixpkgs.${version};
  };

  envToBash = name: value: "export ${name}=${lib.escapeShellArg (toString value)}";
  startupEnv = lib.concatStringsSep "\n" (lib.mapAttrsToList envToBash envVariables);

  # default poetry.toml file
  poetryTomlFile = ''
    [virtualenvs]
    in-project = true
    prefer-active-python = true
  '';
in

pkgs.nixpkgs.mkShell {

  nativeBuildInputs = [ pkgs.nixpkgs.bashInteractive ];
  buildInputs = [
    python
    poetry
    pkgs.nixpkgs.zlib
  ] ++ extraPackages;

  shellHook = ''
    if [ ! -f "poetry.toml" ]; then
      echo "${poetryTomlFile}" > poetry.toml
    fi

    if [ ! -f "pyproject.toml" ]; then
      echo "No pyproject.toml file found. Run 'poetry init' to create Poetry project."
    fi

    export PYTHONPATH=${python}/${python.sitePackages}

    ${startupEnv}
    ${shellHook}
  '';
}
