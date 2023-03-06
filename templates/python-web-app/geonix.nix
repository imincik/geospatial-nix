# Simple Geonix configuration.

{ pkgs, geonix, ... }:

let
  # Choose Python version here.
  # Supported versions:
  # * python3   - default Python version (3.10)
  # * python39  - Python 3.9
  # * python310 - Python 3.10
  # * python311 - Python 3.11
  pythonVersion = "python3";

  pythonPackages = [
    # Geonix Python packages
    pkgs.geonix."${pythonVersion}-psycopg"
    pkgs.geonix."${pythonVersion}-shapely"

    # Other Python packages from Nixpkgs
    # pkgs.nixpkgs.<PYTHON-VERSION>.pkgs.<PACKAGE>
    pkgs.nixpkgs.${pythonVersion}.pkgs.matplotlib

    # The rest of the Python dependencies are managed by Poetry.
    # See: pyproject.toml file.
  ];

  extraPackages = [
    # Geonix CLI
    pkgs.geonix.geonixcli

    # Non-Python packages from Nixpkgs.
    # pkgs.nixpkgs.<PACKAGE>
    pkgs.nixpkgs.postgresql # to get psql client
  ];

in
{

  # Development shells.
  # For list of available shell functions see:
  # https://github.com/imincik/geonix/wiki/Packages-images-shell-environments#shell-environments
  shells = {

    # Default interactive shell.
    # Launch shell: nix develop

    default = geonix.lib.mkPythonDevShell {
      inherit pkgs;

      version = pythonVersion;

      extraPythonPackages = pythonPackages;
      extraPackages = extraPackages;

      envVariables = {
        PGHOST = "localhost";
        PGPORT = "15432";
        PGUSER = "postgres";

        WELCOME_MESSAGE = "Welcome Pythonista !";
      };

      shellHook = ''
        export DOCKER_UID=$(id -u)
        export DOCKER_GID=$(id -g)

        echo "$WELCOME_MESSAGE"
        echo -e "\nUsing $(python --version)."
        echo
      '';
    };

    # Postgresql shell.
    # Launch shell: nix develop .#postgresql
    postgresql = geonix.lib.mkPostgresqlShell {
      inherit pkgs;
    };

  };


  # Packages
  packages = {

    container = geonix.lib.mkPythonContainer {
      inherit pkgs;

      name = "python-app-base";

      pythonVersion = pythonVersion;
      extraPythonPackages = pythonPackages;
      extraPackages = extraPackages;
    };
  };
}
