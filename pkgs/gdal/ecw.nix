{ lib
, stdenv
, requireFile
, autoPatchelfHook

, getent
, unzip

, libz
}:

let
  downloadUrl = "https://supportsi.hexagon.com/help/s/article/ERDAS-ECW-JP2-SDK-Read-Only-Redistributable-download";
  version = "5.5.0.2268-Update4";

in
stdenv.mkDerivation {
  pname = "ecw-sdk";
  version = version;

  src = requireFile rec {
    name = "ECWJP2SDKSetup_${version}-Linux.zip";
    hash = "sha256-4Uarru1XTcL/Coomy4PwOPyOvCliiZa7Z+sww8lac5k=";

    message = ''
      In order to use ECW SDK, you need to comply with the Hexagon EULA and
      download the installer file '${name}' from:

      ${downloadUrl}

      Once you have downloaded the file, please use the following command and
      re-run the installation:

      nix store prefetch-file file://\$PWD/${name}
    '';
  };

  unpackPhase = ''
    unzip $src
  '';

  patchPhase = ''
    chmod +x *.bin
    patchShebangs .
  '';

  dontBuild = true;
  dontConfigure = true;
  sourceRoot = ".";
  preferLocalBuild = true;

  nativeBuildInputs = [
    autoPatchelfHook
    getent
    unzip
  ];

  buildInputs = [
    libz
  ];

  runtimeDependencies = [
  ];

  installPhase = ''
    HOME=$PWD
    bash $PWD/ECWJP2SDKSetup*.bin --accept-eula=yes --install-type=1

    mkdir $out
    cp -a hexagon/ERDAS-ECW*/Desktop_Read-Only/* $out
  '';

  meta = with lib; {
    description = "ECW Compression - shrink big data with Enhanced Compression Wavelet (ECW)";
    homepage = "https://hexagon.com";
    # license = licenses.unfree;  # FIXME: enable license
    maintainers = with maintainers; teams.geospatial.members;
    platforms = platforms.linux;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
