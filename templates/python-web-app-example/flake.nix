{
  description = "Example Python web application";

  nixConfig.extra-substituters = [ "https://geonix.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "geonix.cachix.org-1:iyhIXkDLYLXbMhL3X3qOLBtRF8HEyAbhPXjjPeYsCl0=" ];

  nixConfig.bash-prompt = "\\[\\033[1m\\][geonix]\\[\\033\[m\\]\\040\\w >\\040";

  inputs.geonix.url = "github:imincik/geonix";
  inputs.nixpkgs.follows = "geonix/nixpkgs";

  inputs.utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, geonix, utils }:
    utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
      let

        pkgs = geonix.lib.getPackages {
          inherit system nixpkgs geonix;

          pythonVersion = pythonVersion;

          # Run 'geonix override' command to get overrides.nix template file and
          # enable following line to start customizing Geonix packages.

          # overridesFile = ./overrides.nix;
        };

        # Choose Python version here.
        # Supported versions:
        # * python3   - default Python version (3.10)
        # * python39  - Python 3.9
        # * python310 - Python 3.10
        # * python311 - Python 3.11
        pythonVersion = "python3";

        pythonPackages = [
          # Geonix Python packages
          pkgs.geonix."${pythonVersion}-psycopg"
          pkgs.geonix."${pythonVersion}-shapely"

          # Other Python packages from Nixpkgs
          # pkgs.nixpkgs.<PYTHON-VERSION>.pkgs.<PACKAGE>
          pkgs.nixpkgs.${pythonVersion}.pkgs.matplotlib

          # The rest of the Python dependencies are managed by Poetry.
          # See: pyproject.toml file.
        ];

        extraDevPackages = [
          # Geonix CLI
          pkgs.geonix.geonixcli

          # Poetry CLI
          (pkgs.nixpkgs.poetry.override { python = pkgs.nixpkgs.${pythonVersion}; })

          # Non-Python packages from Nixpkgs.
          # pkgs.nixpkgs.<PACKAGE>
          pkgs.nixpkgs.docker-compose
          pkgs.nixpkgs.postgresql # to get psql client
        ];

        postgresqlPackages = [
          # Additional PostgreSQL extensions built in to PostgreSQL container
          # image.

          # pkgs.nixpkgs.<POSTGRESQL-VERSION>.pkgs.<PACKAGE>
          # pkgs.nixpkgs.postgresql.pkgs.pgrouting
        ];

      in
      {

        #
        ### PACKAGES ###
        #

        packages = rec {

          # Extendible PostgreSQL/PostGIS container image provided by Geonix
          postgresqlImage = pkgs.imgs.geonix-postgresql-image.override
            {
              extraPostgresqlPackages = postgresqlPackages;
            };
        };


        #
        ### SHELLS ###
        #

        devShells = rec {

          # Development shell
          dev = pkgs.nixpkgs.mkShellNoCC {

            # List of packages to be present in shell environment
            packages = [
              # Geonix CLI
              pkgs.geonix.geonixcli

              pkgs.nixpkgs.${pythonVersion}

              pythonPackages
              extraDevPackages
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

              echo "$WELCOME_MESSAGE"
              echo -e "\nUsing $(python --version)."

              echo -e "\nLaunch Flask server:"
              echo " poetry install"
              echo " poetry run flask run --reload"

              echo -e "\nLaunch Flask server with DB:"
              echo " nix build .#postgresqlImage"
              echo " docker load < ./result"
              echo " docker-compose up -d"
              echo " BACKEND=db poetry run flask run --reload"

              echo -e "\nConnect to DB:"
              echo " psql"

              echo -e "\nSearch for additional packages:"
              echo " geonix search <PACKAGE>"
              echo
            '';
          };

          default = dev;
        };
      });
}
