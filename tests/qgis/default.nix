# import ./make-test-python.nix ({ pkgs, lib, ... }: {
#   name = "qgis";
#   meta = {
#     maintainers = lib.teams.geospatial.members;
#   };

{ pkgs, commonx11, qgis, ... }:

{
  name = "test QGIS";

  nodes.machine = {
    imports = [ commonx11 ];
    environment.systemPackages = with pkgs; [ grass qgis xdotool ];
  };

  enableOCR = true;

  testScript =
    let
      testData = pkgs.fetchgit {
        name = "qgis-test-data";
        url = "https://github.com/qgis/QGIS.git";
        rev = "63860ec05b49c5ce3ac14b6d7d1fb4ab1987333f";
        hash = "sha256-bN8x+J4+ScaEJlxVnI/CQhBgObqy4Mo73v+WiERMkZ4=";
        sparseCheckout = [
          "tests/testdata/points.*"
          "tests/testdata/lines.*"
          "tests/testdata/polys.*"
          "tests/testdata/quickapp_project.qgs"
        ];
      };

      testProject = "tests/testdata/quickapp_project.qgs";

      testScript = builtins.toFile "test.py" ''
        import osgeo  # to check if geo python environment is present

        from qgis.core import *
        from qgis.utils import *

        from qgis.core import QgsProject

        project = QgsProject.instance()
        project.read("qgis-test-data/tests/testdata/quickapp_project.qgs")

        iface.messageBar().pushMessage(
                "Success",
                "QGIS test is successfully finished !",
                level=Qgis.Success, duration=1000
        )
      '';
    in
    ''
      machine.wait_for_x()

      machine.execute("cp -av ${testData} qgis-test-data")
      # machine.succeed("qgis --nologo --code ${testScript} ${testData}/${testProject} >&2 &")
      machine.succeed("qgis --nologo --code ${testScript} >&2 &")
      machine.wait_for_window(".*quickapp_project.*")
      machine.sleep(5)
      machine.screenshot("screen1")

      # machine.execute("xdotool key Alt+F11")  # maximize window in icewm
      # machine.wait_for_text("QGIS test is successfully finished !")
      # machine.screenshot("screen2")
    '';
}
