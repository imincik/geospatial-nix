{
  python-container = {
    description = "Python container images";
    path = ./templates/python-container;
    welcomeText = ''
      This template allows you to build and run following containers:

      * Python CLI container with Geonix packages
      * Jupyter container with Geonix packages

      ## Usage

      * Lock flake dependencies

        ```
        nix flake lock
        ```

      * Add all files to git !

        ```
        git add *
        ```

      * Build container image (Python)

        ```
        nix build .#pythonImage
        ```

      * Build container image (Jupyter)

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

      * Lock flake dependencies

        ```
        nix flake lock
        ```

      * Add all files to git !

        ```
        git add *
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

      * Launch Python application development server

        ```
        poetry run flask run
        ```

      ### Building container image

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
