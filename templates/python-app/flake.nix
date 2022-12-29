{
  description = "Python application";

  nixConfig.extra-substituters = [ "https://geonix.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "geonix.cachix.org-1:iyhIXkDLYLXbMhL3X3qOLBtRF8HEyAbhPXjjPeYsCl0=" ];

  nixConfig.bash-prompt = "\\[\\033[1m\\][geonix]\\[\\033\[m\\]\\040\\w >\\040";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
  inputs.geonix.url = "github:imincik/geonix";
  inputs.utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, geonix, utils }:
    utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
      let
        # CVE-2022-42966
        insecurePackages = [ "python3.10-poetry-1.2.2" ];

        pkgs = import nixpkgs {
          inherit system;

          config = { permittedInsecurePackages = insecurePackages; };

          # add Geonix overlay with packages under geonix namespace (pkgs.geonix.<PACKAGE>)
          overlays = [ geonix.overlays.${system} ];
        };

        # Choose your Python version here.
        # Supported versions:
        # * python37
        # * python38
        # * python39
        # * python310
        # * python311
        geonixPython = pkgs.python3;

        geonixPackages = [
          # Geonix packages
          pkgs.geonix.python-shapely
        ];

      in
      {

        #
        ### PACKAGES ###
        #

        packages = rec {

          # See mkPoetryApplication documentation:
          # https://github.com/nix-community/poetry2nix#mkPoetryApplication

          # Poetry application packaged by Nix
          poetryApp = pkgs.poetry2nix.mkPoetryApplication {
            projectDir = ./.;
            preferWheels = false;

            # Always add geonix packages as buildInputs to avoid mixing them
            # with Poetry installed packages. buildInputs are installed on
            # separate PYTHONPATH.
            propagatedBuildInputs = geonixPackages;

            # If some package fails to build, see how to fix it.
            # https://github.com/nix-community/poetry2nix/blob/master/docs/edgecases.md
            # overrides = poetry2nix.overrides.withDefaults (self: super: {
            #   foo = foo.overridePythonAttrs(oldAttrs: {});
            # });
          };

          # See dockerTools documentation:
          # https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-dockerTools

          # Poetry application container image
          poetryAppImage = pkgs.dockerTools.buildLayeredImage {
            name = "geonix-python-app";
            tag = "latest";
            created = "now"; # optional - breaks reproducibility by setting current date
            contents = [ poetryApp ];
            config = {
              Cmd = [
                "${poetryApp.dependencyEnv}/bin/flask"
                "run"
                "--host"
                "0.0.0.0"
              ];
              ExposedPorts = {
                "5000/tcp" = { };
              };
            };
          };

          default = poetryAppImage;
        };


        #
        ### SHELLS ###
        #

        devShells = {

          # Default development shell
          default = pkgs.mkShellNoCC {

            # list of packages to be present in shell environment
            packages = [

              # Python interpreter
              geonixPython

              # Poetry CLI running in Geonix Python interpreter
              (pkgs.poetry.override { python = geonixPython; })

              # Packages from Nixpkgs
              # Search for additional Python packages from Nixpkgs:
              # $ nix search nixpkgs/nixos-22.11 "<PACKAGE>"
              # and add them in following format below:

              # pkgs.<PACKAGE>
              pkgs.shellcheck

            ] ++ geonixPackages; # Geonix Python packages

            # Environment variable passed to shell
            WELCOME_MESSAGE = "Welcome here !";

            # Shell commands to execute after shell environment is started
            shellHook = ''
              echo "$WELCOME_MESSAGE"
            '';
          };
        };
      });
}
