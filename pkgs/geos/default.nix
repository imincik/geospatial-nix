{ lib
, callPackage
, fetchFromGitHub
, stdenv
, testers
, cmake
}:

stdenv.mkDerivation (finalAttrs: rec {
  pname = "geos";
  version = "3.12.0";

  src = fetchFromGitHub {
    owner = "libgeos";
    repo = "geos";
    rev = version;
    hash = "sha256-y5Pb+b3WeMTqC2nwz2Jzi0WwPb89zUs8Nb1VNauuG6A=";
  };

  nativeBuildInputs = [ cmake ];

  doCheck = true;

  passthru.tests = {
    geos = callPackage ./tests.nix { geos = finalAttrs.finalPackage; };
    pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = with lib; {
    description = "C++ port of the Java Topology Suite (JTS)";
    homepage = "https://trac.osgeo.org/geos";
    license = licenses.lgpl21Only;
    pkgConfigModules = [ "geos" ];
    maintainers = with lib.maintainers; [
      willcohen
    ];
  };
})
