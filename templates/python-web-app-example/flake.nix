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
        nix = import nixpkgs {
          inherit system;
        };

        pkgs = {
          nixpkgs = nixpkgs.legacyPackages.${system};

          geonix = geonix.packages.${system};
          imgs = geonix.packages.x86_64-linux;
        };

        # Choose Python version here.
        # Supported versions:
        # * python37
        # * python38
        # * python39
        # * python310
        # * python311
        pythonInterpreter = pkgs.nixpkgs.python3;

        pythonPackages = [

          # Geonix Python packages
          pkgs.geonix.python-psycopg
          pkgs.geonix.python-shapely

          # Python packages from Nixpkgs.
          # pkgs.nixpkgs.<PYTHON-VERSION>.pkgs.<PACKAGE>
          pkgs.nixpkgs.python3.pkgs.matplotlib
        ];

        postgresqlPackages = [

          # Additional PostgreSQL extensions built in to PostgreSQL container
          # image.

          # pkgs.<POSTGRESQL-VERSION>.pkgs.<PACKAGE>
          # pkgs.postgresql.pkgs.pgrouting
        ];

      in
      {

        #
        ### PACKAGES ###
        #

        packages = rec {

          # Extendible PostgreSQL/PostGIS container image provided by Geonix
          postgresImage = pkgs.imgs.geonix-postgresql-image.override
          {
            extraPostgresqlPackages = postgresqlPackages;
          };


          # See mkPoetryApplication documentation:
          # https://github.com/nix-community/poetry2nix#mkPoetryApplication

          # Poetry application packaged by Nix
          poetryApp = nix.poetry2nix.mkPoetryApplication {
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
          poetryAppImage = nix.dockerTools.buildLayeredImage {
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
          dev = nix.mkShellNoCC {

            # List of packages to be present in shell environment
            packages = [

              # Geonix CLI
              pkgs.geonix.geonixcli

              # Python interpreter
              pythonInterpreter

              # Geonix Python packages
              pythonPackages

              # Poetry CLI running in Geonix Python interpreter
              (pkgs.nixpkgs.poetry.override { python = pythonInterpreter; })

              # Other useful packages from Nixpkgs
              # pkgs.nixpkgs.<PACKAGE>
              pkgs.nixpkgs.black
              pkgs.nixpkgs.isort

              pkgs.nixpkgs.docker-compose
              pkgs.nixpkgs.postgresql # to get psql client
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
              echo " poetry install"
              echo " poetry run flask run --reload"

              echo -e "\nLaunch Flask server with DB:"
              echo " nix build .#postgresImage"
              echo " docker load < ./result"
              echo " docker-compose up -d"
              echo " BACKEND=db poetry run flask run --reload"

              echo -e "\nConnect to DB:"
              echo " psql"

              echo -e "\nSearch for additional packages:"
              echo " geonix search <PACKAGE>"
            '';
          };

          default = dev;
        };
      });
}
