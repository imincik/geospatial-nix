{
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

      * Enter development shell

        ```
        nix develop
        ```

      * Install Python virtual environment managed by Poetry

        ```
        poetry install
        ```

      * Launch Python application development server

        ```
        poetry run flask run --reload
        ```

      * Exit development shell

        ```
        exit
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

      ### Publish application and run it from GitHub

      * Create new GitHub repository

      * Add and commit all files to git

        ```
        git add *
        git commit -m "Python application from Geonix python-app template"
        ```

      * Push application to GitHub

        ```
        git remote add origin https://github.com/<OWNER>/<REPOSITORY>.git
        git branch -M master
        git push -u origin master
        ```

      * Launch application from GitHub

        ```
        nix run github:<OWNER>/<REPOSITORY>
        ```
        ```
        or try:
        nix run github:imincik/geonix-python-app
        ```

      ## More info

      * [Nixpkgs dockerTools](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-dockerTools)
      * [mkPoetryApplication](https://github.com/nix-community/poetry2nix#mkPoetryApplication)
      * [Nix tutorials](https://nix.dev)
    '';
  };
}
