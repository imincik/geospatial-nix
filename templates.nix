{
  python-container = {
    description = "Python container images";
    path = ./templates/python-container;
    welcomeText = ''
      This template allows you to build and run following containers:

      * Python CLI container with Geonix packages
      * Jupyter container with Geonix packages

      ## Usage
      * Add flake.nix and flake.lock files to git !
      ```
      git add flake.nix flake.lock
      ```

      * Build container image
      ```
      nix build .#pythonImage
      ```

      OR

      ```
      nix build .#jupyterImage
      ```

      * Load image to Docker
      ```
      docker load < result
      ```

      * Run Python container interactively
      ```
      docker run -it geonix-python
      ```

      * Run script in Python container
      ```
      docker run geonix-python -c "import fiona; print(fiona.show_versions())"
      ```

      * Run Jupyter container
      ```
      docker run -p 8888:8888 geonix-jupyter
      ```

      ## More info
      * [Nixpkgs dockerTools](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-dockerTools)
      * [Nix tutorials](https://nix.dev)
    '';
  };


  python-app = {
    description = "Python application";
    path = ./templates/python-app;
    welcomeText = ''
      This template allows you to develop a Python application with dependencies
      managed by Poetry.

      ## Usage
      * Add flake.nix and flake.lock files to git !
      ```
      git add flake.nix flake.lock
      ```

      ### Development
      * Enter development shell (run following command in shell environment)
      ```
      nix develop
      ```

      * Install Python virtual environment managed by Poetry
      ```
      poetry install
      ```

      * Add poetry.lock file to git
      ```
      git add poetry.lock
      ```

      * Launch Python application development server
      ```
      poetry run flask run
      ```

      ### Packaging in container image
      * Build container image
      ```
      nix build .#poetryAppImage
      ```

      * Load image to Docker
      ```
      docker load < result
      ```

      * Run container
      ```
      docker run -p 5000:5000 geonix-python-app
      ```

      ## More info
      * [Nixpkgs dockerTools](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-dockerTools)
      * [mkPoetryApplication](https://github.com/nix-community/poetry2nix#mkPoetryApplication)
      * [Nix tutorials](https://nix.dev)
    '';
  };
}
