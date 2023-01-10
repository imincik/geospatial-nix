{ lib, makeWrapper, symlinkJoin
, extraPythonPackages ? (ps: [ ])
, qgis-unwrapped
}:
with lib;

symlinkJoin rec {

  inherit (qgis-unwrapped) version src;
  name = "qgis-${version}";

  paths = [ qgis-unwrapped ];

  nativeBuildInputs = [ makeWrapper qgis-unwrapped.py.pkgs.wrapPython ];

  # extend to add to the python environment of QGIS without rebuilding QGIS application.
  pythonInputs = qgis-unwrapped.pythonBuildInputs ++ (extraPythonPackages qgis-unwrapped.py.pkgs);

  postBuild = ''
    # unpackPhase

    buildPythonPath "$pythonInputs"

    wrapProgram $out/bin/qgis \
      --prefix PATH : $program_PATH \
      --set PYTHONPATH $program_PYTHONPATH
  '';

  passthru.unwrapped = qgis-unwrapped;

  meta = qgis-unwrapped.meta;
}
