{ nixpkgs, pkgs, lib, nixGLIntel, ... }:

  let
    testX11Module = import "${toString nixpkgs}/nixos/tests/common/x11.nix";

  in
  {
    name = "nixGL";

    nodes = {
      machine = { pkgs, ... }: {
        virtualisation.diskSize = 2 * 1024;

        imports = [ testX11Module ];
        environment.systemPackages = [ nixGLIntel pkgs.glxinfo];
      };
    };

    testScript = ''
      start_all()

      machine.wait_for_x()
      machine.succeed("${nixGLIntel}/bin/nixGLIntel ${pkgs.glxinfo}/bin/glxinfo | grep -i 'OpenGL version string'")
    '';
  }
