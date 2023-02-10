# Simple Geonix configuration.

{ pkgs, geonix, ... }:

{

  # List of packages for default interactive shell.
  # Enter shell: nix develop
  packages = [
    pkgs.geonix.geonixcli
    pkgs.geonix.gdal
    pkgs.geonix.pdal
    # pkgs.geonix.qgis
  ];


  # List of service shells.
  shells = {

    # Postgresql shell
    # Launch shell: nix develop .#postgresql
    postgresql = geonix.lib.mkPostgresqlShell {
      inherit pkgs;
      version = "postgresql_12";
    };

    # pgAdmin shell
    # Launch shell: nix develop .#pgadmin
    pgadmin = geonix.lib.mkPgAdminShell {
      inherit pkgs;
    };

  };

}
