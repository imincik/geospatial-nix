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
  version = "1.9.4";

  disabled = pythonOlder "3.7";

  format = "pyproject";

  src = fetchFromGitHub {
    owner = "Toblerity";
    repo = "Fiona";
    rev = "refs/tags/${version}";
    hash = "sha256-v4kTjoGu4AiEepBrGyY1e1OFC1eCk/U6f8XA/vtfY0E=";
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

  disabledTests = [
    # Some tests access network, others test packaging
    "http"
    "https"
    "wheel"

    # see: https://github.com/Toblerity/Fiona/issues/1273
    "test_append_memoryfile_drivers"
  ];

  pythonImportsCheck = [ "fiona" ];

  doInstallCheck = true;

  installCheckPhase = ''
    $out/bin/fio --version | grep -E "fio,\sversion\s${version}" > /dev/null
    $out/bin/fio --gdal-version | grep -E "GDAL,\sversion\s[0-9]+(\.[0-9]+)*" > /dev/null
  '';

  meta = with lib; {
    changelog = "https://github.com/Toblerity/Fiona/blob/${src.rev}/CHANGES.txt";
    description = "OGR's neat, nimble, no-nonsense API for Python";
    homepage = "https://fiona.readthedocs.io/";
    license = licenses.bsd3;
    maintainers = with maintainers; [ knedlsepp ];
  };
}
