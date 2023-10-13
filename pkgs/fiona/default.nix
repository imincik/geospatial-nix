{ lib
, buildPythonPackage
, pythonOlder
, fetchFromGitHub
, cython
, gdal
, setuptools
, attrs
, certifi
, click
, click-plugins
, cligj
, importlib-metadata
, munch
, shapely
, boto3
, pytestCheckHook
, pytz
}:

buildPythonPackage rec {
  pname = "fiona";
  version = "1.9.5";
  format = "pyproject";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "Toblerity";
    repo = "Fiona";
    rev = "refs/tags/${version}";
    hash = "sha256-fq/BuyzuK4iOxdpE4h+KRH0CxOEk/wdmbb9KgCfJ1cw=";
  };

  nativeBuildInputs = [
    cython
    gdal # for gdal-config
    setuptools
  ];

  buildInputs = [
    gdal
  ];

  propagatedBuildInputs = [
    attrs
    certifi
    click
    cligj
    click-plugins
    munch
  ] ++ lib.optionals (pythonOlder "3.10") [
    importlib-metadata
  ];

  passthru.optional-dependencies = {
    calc = [ shapely ];
    s3 = [ boto3 ];
  };

  nativeCheckInputs = [
    pytestCheckHook
    pytz
  ] ++ passthru.optional-dependencies.s3;

  preCheck = ''
    rm -r fiona # prevent importing local fiona
  '';

  pytestFlagsArray = [
    # Tests with gdal marker do not test the functionality of Fiona,
    # but they are used to check GDAL driver capabilities.
    "-m 'not gdal'"
  ];

  disabledTests = [
    # Some tests access network, others test packaging
    "http"
    "https"
    "wheel"

    # see: https://github.com/Toblerity/Fiona/issues/1273
    "test_append_memoryfile_drivers"
  ];

  pythonImportsCheck = [
    "fiona"
  ];

  doInstallCheck = true;

  meta = with lib; {
    changelog = "https://github.com/Toblerity/Fiona/blob/${src.rev}/CHANGES.txt";
    description = "OGR's neat, nimble, no-nonsense API for Python";
    homepage = "https://fiona.readthedocs.io/";
    license = licenses.bsd3;
    maintainers = with maintainers; [ knedlsepp ];
  };
}
