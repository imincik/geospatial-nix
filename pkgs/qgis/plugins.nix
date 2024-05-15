{ fetchurl
, stdenv

, unzip

, name
, plugin
}:

stdenv.mkDerivation {
  pname = "qgis-plugin-${name}";
  version = "3.19.0";

  src = fetchurl {
    url = plugin.url;
    sha256 = plugin.hash;
  };

  dontUnpack = true;

  nativeBuildInputs = [ unzip ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    unzip -d $out $src

    find . -name '*.pyc' -type f -delete

    runHook postInstall
  '';

  meta = {
    description = "QGIS plugin";
    homepage = "https://plugins.qgis.org/plugins";
  };
}

