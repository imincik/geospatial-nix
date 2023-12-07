{
  workspace = {
    description = "Geospatial workspace";
    path = ./templates/workspace;
    welcomeText = ''
      See README.md file for instructions how to use this template.
    '';
  };


  python-web-app = {
    description = "Example Python web application";
    path = ./templates/python-web-app;
    welcomeText = ''
      See README.md file for instructions how to use this template.
    '';
  };


  simple = {
    description = "Simple environment";
    path = ./templates/simple;
    welcomeText = ''
      See README.md file for instructions how to use this template.
    '';
  };

  simple-devenv = {
    description = "Simple environment based on Devenv";
    path = ./templates/simple-devenv;
    welcomeText = ''
      See README.md file for instructions how to use this template.
    '';
  };
}
