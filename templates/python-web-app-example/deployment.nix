{ stdenv
, pkgs
, lib ? pkgs.lib
, pythonVersion
, pythonPackages
}:

let
  entrypoint =
    pkgs.writeShellScriptBin "entrypoint"
      ''
      set -euo pipefail

      source .venv/bin/activate
      flask --app src/python_app run --host 0.0.0.0 --port 8000
      '';
in

stdenv.mkDerivation rec {
  pname = "container-deployment";
  version = "0.1.0";

  src = ./.;

  unpackPhase = "true";
  buildPhase = "true";

  nativeBuildInputs = [ pkgs.makeWrapper pkgs.${pythonVersion}.pkgs.wrapPython ];

  pythonPath = pythonPackages;

  installPhase = ''
    mkdir -p $out/bin

    cp ${entrypoint}/bin/entrypoint $out/bin/entrypoint

    buildPythonPath "$pythonPath"

    wrapProgram $out/bin/entrypoint \
      --prefix PATH : $program_PATH \
      --set PYTHONPATH $program_PYTHONPATH
  '';

  meta = with lib; {
    description = "Container deployment";
    homepage = "https://github.com/imincik/geonix";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ imincik ];
  };
}
