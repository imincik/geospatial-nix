{ lib }:

{
  # Function: getPackages
  # Return packages as packages attribute sets in following format:

    # pkgs = {
    #   nixpkgs;
    #   geonix;
    #   imgs;
    # };

  # If overridesFile parameter is used, apply packages overrides from this file.

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
  mkpgAdminShell = import ./pgadmin-shell.nix;
  mkPostgresqlShell = import ./postgresql-shell.nix;
  mkpsqlShell = import ./psql-shell.nix;
}
