{ lib
, stdenv
, callPackage
, fetchFromGitHub
, cmake }:

stdenv.mkDerivation (finalAttrs: rec {
  pname = "geos";
  version = "3.11.1";

  src = fetchFromGitHub {
    owner = "libgeos";
    repo = "geos";
    rev = version;
    hash = "sha256-4jm/T9KzT4AV12YKsGEnLN/AybqvLhTgWBl58JXpIZY=";
  };

  nativeBuildInputs = [ cmake ];

  doCheck = true;

  passthru.tests = {
    geos = callPackage ./tests.nix { geos = finalAttrs.finalPackage; };
  };

  meta = with lib; {
    description = "C++ port of the Java Topology Suite (JTS)";
    homepage = "https://trac.osgeo.org/geos";
    license = licenses.lgpl21Only;
    maintainers = with lib.maintainers; [
      willcohen
    ];
  };
})
