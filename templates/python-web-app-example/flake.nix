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
        pythonInterpreter = pkgs.python3;

        pythonPackages = [

          # Geonix Python packages
          pkgs.geonix.python-shapely

          # Python packages from Nixpkgs.
          # Search for additional Python packages from Nixpkgs:
          # $ nix search nixpkgs/nixos-22.11 "python3.*Packages.<PACKAGE>"
          # and add them in following format below:

          # pkgs.<PYTHON-VERSION>.pkgs.<PACKAGE>
          pkgs.python3.pkgs.matplotlib
          pkgs.python3.pkgs.psycopg
        ];

      in
      {

        #
        ### PACKAGES ###
        #

        packages = utils.lib.filterPackages system rec {

          # PostgreSQL/PostGIS container image provided by Geonix
          postgresImage = geonix.packages.x86_64-linux.image-postgres;

          # See mkPoetryApplication documentation:
          # https://github.com/nix-community/poetry2nix#mkPoetryApplication

          # Poetry application packaged by Nix
          poetryApp = pkgs.poetry2nix.mkPoetryApplication {
            projectDir = ./.;
            preferWheels = false;

            # Python interpreter
            python = pythonInterpreter;

            # Always add Geonix Python packages as buildInputs to avoid mixing
            # them with Poetry installed packages. buildInputs are installed on
            # separate PYTHONPATH.
            propagatedBuildInputs = pythonPackages;

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
            name = "geonix-python-web-app-example";
            tag = "latest";

            # Breaks reproducibility by setting current timestamp during each build.
            # created = "now";

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

        devShells = rec {

          # Development shell
          dev = pkgs.mkShellNoCC {

            # List of packages to be present in shell environment
            packages = [

              # Python interpreter
              pythonInterpreter

              # Geonix Python packages
              pythonPackages

              # Poetry CLI running in Geonix Python interpreter
              (pkgs.poetry.override { python = pythonInterpreter; })

              # Other useful packages from Nixpkgs
              # Search for additional packages from Nixpkgs:
              # $ nix search nixpkgs/nixos-22.11 "<PACKAGE>"
              # and add them in following format below:

              # pkgs.<PACKAGE>
              pkgs.black
              pkgs.isort

              pkgs.docker-compose
              pkgs.postgresql  # to get psql client

            ];

            # Environment variable passed to shell
            PGHOST = "localhost";
            PGPORT = "15432";
            PGUSER = "postgres";

            WELCOME_MESSAGE = "Welcome Pythonista !";

            # Shell commands to execute after shell environment is started
            shellHook = ''
              export DOCKER_UID=$(id -u)
              export DOCKER_GID=$(id -g)

              echo -e "\n$WELCOME_MESSAGE"

              echo -e "\nLaunch Flask server:"
              echo " poetry run flask run --reload"

              echo -e "\nLaunch Flask server with DB:"
              echo " nix build .#postgresImage"
              echo " docker load < ./result"
              echo " docker-compose up -d"
              echo " BACKEND=db poetry run flask run --reload"

              echo -e "\nConnect to DB:"
              echo " psql"
            '';
          };

          default = dev;
        };
      });
}
