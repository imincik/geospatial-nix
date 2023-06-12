{ lib }:

{
  /*

  Function: getPackages
  Description: Return packages as packages attribute sets in following format:

    pkgs = {
      nixpkgs;
      geonix;
    };

  If overridesFile parameter is used, apply packages overrides from this file.

  Parameters:
  * system:             supported system name. Use `inherit system;`
                        Example: `x86_64-linux`.

  * nixpkgs:            nixpkgs attribute set. Use `inherit nixpkgs;`

  * geonix:             geonix attribute set. User `inherit geonix;`

  * pythonVersion:      Python version.
                        Example: `python39`. Default: `python3`

  * postgresqlVersion:  PostgreSQL version.
                        Example: `postgresql_12. `Default: `postgresql`

  * overridesFile:      file containing packages overrides definitions.
                        Default: false
  */

  getPackages = {
    system, nixpkgs, geonix,
    pythonVersion ? "python3", postgresqlVersion ? "postgresql",
    overridesFile ? false
  }:

    if overridesFile != false then
      {
        nixpkgs = nixpkgs.legacyPackages.${system};
        geonix =
          let
            geonixOverPkgs = import overridesFile {
              nixpkgs = nixpkgs.legacyPackages.${system};
              pkgs = geonix.packages.${system};
              pythonVersion = pythonVersion;
              postgresqlVersion = postgresqlVersion;
            };
          in
            geonixOverPkgs

            # Python packages
            // lib.mapAttrs'
                (name: value: { name = "${pythonVersion}-" + name; value = value; })
                geonixOverPkgs.python-packages

            # PostgreSQL packages
            // lib.mapAttrs'
                (name: value: { name = "${postgresqlVersion}-" + name; value = value; })
                geonixOverPkgs.postgresql-packages;
      }

    else
      {
        nixpkgs = nixpkgs.legacyPackages.${system};
        geonix = geonix.packages.${system};
      };


  # mkShell functions
  mkDevShell = import ./dev-shell.nix;
  mkPgAdminShell = import ./pgadmin-shell.nix;
  mkPostgresqlClientShell = import ./postgresql-client-shell.nix;
  mkPostgresqlShell = import ./postgresql-shell.nix;
  mkPythonDevShell = import ./python-shell.nix;

  mkPostgresqlContainer = import ./postgresql-container.nix;
  mkPythonContainer = import ./python-container.nix;
}
