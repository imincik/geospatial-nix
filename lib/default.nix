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

  getPackages = { system, nixpkgs, geonix, pythonVersion ? "python3", overridesFile ? false }:

    if overridesFile != false then
      {
        nixpkgs = nixpkgs.legacyPackages.${system};
        geonix =
          let
            geonixOverPkgs = import overridesFile {
              nixpkgs = nixpkgs.legacyPackages.${system};
              pkgs = geonix.packages.${system};
              pythonVersion = pythonVersion;
            };
          in
          geonixOverPkgs
          // lib.mapAttrs' (name: value: { name = "${pythonVersion}-" + name; value = value; }) geonixOverPkgs.python-packages;

        imgs = import overridesFile {
          nixpkgs = nixpkgs.legacyPackages.x86_64-linux;
          pkgs = geonix.packages.x86_64-linux;
          pythonVersion = pythonVersion;
        };
      }

    else
      {
        nixpkgs = nixpkgs.legacyPackages.${system};
        geonix = geonix.packages.${system};
        imgs = geonix.packages.x86_64-linux;
      };
}
