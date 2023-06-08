# Simple Geonix configuration.

{ pkgs, geonix, ... }:

{

  # Shell environments.
  # For list of available shell functions see:
  # https://github.com/imincik/geonix/wiki/Packages-images-shell-environments#shell-environments
  shells = {

    # Default interactive shell.
    # Launch shell: nix develop
    default = geonix.lib.mkDevShell {
      inherit pkgs;

      extraPackages = [
        pkgs.geonix.geonixcli
        pkgs.geonix.gdal
        # ...
      ];
    };

    # Postgresql shell.
    # Launch shell: nix develop .#postgresql
    postgresql = geonix.lib.mkPostgresqlShell {
      inherit pkgs;
    };

  };

}
