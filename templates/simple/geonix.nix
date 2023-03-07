# Simple Geonix configuration.

{ pkgs, geonix, ... }:

{

  # List of service shells.
  shells = {

    # Default interactive shell.
    # Launch shell: nix develop
    default = geonix.lib.mkDevShell {
      inherit pkgs;
      extraPackages = [
        pkgs.geonix.geonixcli
        pkgs.geonix.gdal
        pkgs.geonix.pdal
        # pkgs.geonix.qgis
      ];
    };

    # Postgresql shell.
    # Launch shell: nix develop .#postgresql
    postgresql = geonix.lib.mkPostgresqlShell {
      inherit pkgs;
      postgresqlVersion = "postgresql_12";
    };

    # pgAdmin shell.
    # Launch shell: nix develop .#pgadmin
    pgadmin = geonix.lib.mkPgAdminShell {
      inherit pkgs;
    };

    # PostgreSQL client shell.
    # Launch shell: nix develop .#pgclient
    pgclient = geonix.lib.mkPostgresqlClientShell {
      inherit pkgs;
      postgresqlVersion = "postgresql_12";
    };

  };

}
