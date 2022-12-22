{
  python-container = {
    description = "Python container images";
    path = ./templates/python-container;
    welcomeText = ''
      This template allows you to build and run following containers:

      * Python CLI container with Geonix packages
      * Jupyter container with Geonix packages

      ## Usage
      * flake.nix file must be added to git first !
      ```
      git add flake.nix
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
}
