{ lib, ... }:

{
  customizePackages = import ./customize-packages.nix;

  # mkShell functions
  mkDevShell = import ./dev-shell.nix;
  mkPgAdminShell = import ./pgadmin-shell.nix;
  mkPostgresqlClientShell = import ./postgresql-client-shell.nix;
  mkPostgresqlShell = import ./postgresql-shell.nix;
  mkPythonDevShell = import ./python-shell.nix;

  mkPostgresqlContainer = import ./postgresql-container.nix;
  mkPythonContainer = import ./python-container.nix;
}
