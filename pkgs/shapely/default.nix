{ lib
, stdenv
, buildPythonPackage
, fetchFromGitHub
, substituteAll
, pythonOlder
, geos
, pytestCheckHook
, cython
, numpy
}:

buildPythonPackage rec {
  pname = "Shapely";
  version = "2.0.0";
  disabled = pythonOlder "3.6";

  src = fetchFromGitHub {
    owner = "shapely";
    repo = "shapely";
    rev = "${version}";
    hash = "sha256-VF4RvWM+abVzzL+omjr3LMlNg0uJogTnS3zXD3hfleo=";
  };


  nativeBuildInputs = [
    geos # for geos-config
    cython
  ];

  propagatedBuildInputs = [
    numpy
  ];

  checkInputs = [
    pytestCheckHook
  ];

  # Environment variable used in shapely/_buildcfg.py
  GEOS_LIBRARY_PATH = "${geos}/lib/libgeos_c${stdenv.hostPlatform.extensions.sharedLibrary}";

  patches = [
    # Patch to search form GOES .so/.dylib files in a Nix-aware way
    (substituteAll {
      src = ./library-paths.patch;
      libgeos_c = GEOS_LIBRARY_PATH;
      libc = lib.optionalString (!stdenv.isDarwin) "${stdenv.cc.libc}/lib/libc${stdenv.hostPlatform.extensions.sharedLibrary}.6";
    })
 ];

  preCheck = ''
    rm -r shapely # prevent import of local shapely
  '';

  disabledTests = lib.optionals (stdenv.isDarwin && stdenv.isAarch64) [
    # FIXME(lf-): these logging tests are broken, which is definitely our
    # fault. I've tried figuring out the cause and failed.
    #
    # It is apparently some sandbox or no-sandbox related thing on macOS only
    # though.
    "test_error_handler_exception"
    "test_error_handler"
    "test_info_handler"
  ];

  pythonImportsCheck = [ "shapely" ];

  meta = with lib; {
    description = "Geometric objects, predicates, and operations";
    homepage = "https://pypi.python.org/pypi/Shapely/";
    license = with licenses; [ bsd3 ];
    maintainers = with maintainers; [ knedlsepp ];
  };
}
