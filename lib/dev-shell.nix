/*

Function:         mkDevShell
Description:      Create interactive general purpose development shell.

Parameters:
* pkgs:           set of packages used to build shell environment. Must
                  be in format as returned by getPackages function.

* packages:
                  extra packages to install in shell environment.
                  Example: `pkgs.nixpkgs.tig`. Default: `[]`.

* envVariables:   list of environment variables to set.
                  Example: `{ MESSAGE = "Hi there !"; }`. Default: `{}`.

* shellHook:      Bash script to run when shell environment is loaded.
                  Example: `echo $MESSAGE`. Default: `""`.

*/

{ pkgs
, packages ? []
, envVariables ? {}
, shellHook ? ""
}:

let
  lib = pkgs.nixpkgs.lib;

  envToBash = name: value: "export ${name}=${lib.escapeShellArg (toString value)}";
  startupEnv = lib.concatStringsSep "\n" (lib.mapAttrsToList envToBash envVariables);
in

pkgs.nixpkgs.mkShell {

  nativeBuildInputs = [ pkgs.nixpkgs.bashInteractive ];
  buildInputs = packages;

  shellHook = ''
    ${startupEnv}
    ${shellHook}
  '';
}
