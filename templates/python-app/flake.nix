{
  description = "Python application";

  nixConfig.extra-substituters = [ "https://geonix.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "geonix.cachix.org-1:iyhIXkDLYLXbMhL3X3qOLBtRF8HEyAbhPXjjPeYsCl0=" ];

  nixConfig.bash-prompt = "\\[\\033[1m\\][geonix]\\[\\033\[m\\]\\040\\w >\\040";

  inputs.geonix.url = "github:imincik/geonix";
  inputs.nixpkgs.follows = "geonix/nixpkgs";

  inputs.utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, geonix, utils }:
    utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
      let
        # accept CVE-2022-42966
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

          # Geonix Python packages
          pkgs.geonix.python-shapely

          # Python packages from Nixpkgs
          # Search for additional Python packages from Nixpkgs:
          # $ nix search nixpkgs/nixos-22.11 "python3.*Packages.<PACKAGE>"
          # and add them in following format below:

          # pkgs.<PYTHON-VERSION>.pkgs.<PACKAGE>
          pkgs.python3.pkgs.matplotlib
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

            # Python interpreter
            python = geonixPython;

            # Always add Geonix Python packages as buildInputs to avoid mixing
            # them with Poetry installed packages. buildInputs are installed on
            # separate PYTHONPATH.
            propagatedBuildInputs = geonixPackages;

            # If some package fails to build, see how to fix them.
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
            created = "now"; # optional - breaks reproducibility by updating timestamps
            contents = [ poetryApp ];
            config = {
              Cmd = [ "${poetryApp}/bin/run-app" ];
              ExposedPorts = {
                "5000/tcp" = { };
              };
            };
          };

          default = poetryAppImage;

        };


        #
        ### APPS ##
        #

        apps = rec {

          poetryApp = {
            type = "app";
            program =
              "${self.packages.${system}.poetryApp}/bin/run-app";
          };

          default = poetryApp;

        };


        #
        ### SHELLS ###
        #

        devShells = {

          # Default development shell
          default = pkgs.mkShellNoCC {

            # List of packages to be present in shell environment
            packages = [

              # Python interpreter
              geonixPython

              # Geonix Python packages
              geonixPackages

              # Poetry CLI running in Geonix Python interpreter
              (pkgs.poetry.override { python = geonixPython; })

              # Other useful packages from Nixpkgs
              # Search for additional packages from Nixpkgs:
              # $ nix search nixpkgs/nixos-22.11 "<PACKAGE>"
              # and add them in following format below:

              # pkgs.<PACKAGE>
              pkgs.black
              pkgs.isort

            ];

            # Environment variable passed to shell
            WELCOME_MESSAGE = "Welcome Pythonista !";

            # Shell commands to execute after shell environment is started
            shellHook = ''
              echo "$WELCOME_MESSAGE"
            '';
          };

        };
      });
}
