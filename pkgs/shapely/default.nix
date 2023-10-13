{ lib
, stdenv
, buildPythonPackage
, fetchFromGitHub
, pythonOlder
, cython
, geos
, setuptools
, numpy
, pytestCheckHook
}:

buildPythonPackage rec {
  pname = "shapely";
  version = "2.0.2";
  format = "pyproject";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "shapely";
    repo = "shapely";
    rev = "${version}";
    hash = "sha256-U0kkhHw6gLRC7ZZHChg8ZBWyYG6AXSQle4+iWsnbwMw=";
  };

  nativeBuildInputs = [
    cython
    geos # for geos-config
    setuptools
  ];

  buildInputs = [
    geos
  ];

  propagatedBuildInputs = [
    numpy
  ];

  nativeCheckInputs = [
    pytestCheckHook
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
    changelog = "https://github.com/shapely/shapely/blob/${version}/CHANGES.txt";
    description = "Manipulation and analysis of geometric objects";
    homepage = "https://github.com/shapely/shapely";
    license = licenses.bsd3;
    maintainers = with maintainers; [ knedlsepp ];
  };
}
