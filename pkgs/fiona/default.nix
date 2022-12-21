{ stdenv, lib, buildPythonPackage, fetchFromGitHub, isPy3k, pythonOlder, cython
, attrs, click, cligj, click-plugins, six, munch, enum34
, pytestCheckHook, boto3, mock, giflib, pytz
, gdal, certifi
, fetchpatch
}:

buildPythonPackage rec {
  pname = "fiona";
  version = "1.8.22";

  src = fetchFromGitHub {
    owner = "Toblerity";
    repo = "Fiona";
    rev = "${version}";
    hash = "sha256-C/k+udhRAVsMWUNVE8DdKsXWqlik8Vt2GOuID2X2zJs=";
  };

  patches = [
    # https://github.com/Toblerity/Fiona/pull/1122
    (fetchpatch {
      url = "https://github.com/Toblerity/Fiona/commit/fa632130dcd9dfbb982ecaa4911b3fab3459168f.patch";
      hash = "sha256-IuNHr3yBqS1jY9Swvcq8XPv6BpVlInDx0FVuzEMaYTY=";
    })
  ];

  CXXFLAGS = lib.optionalString stdenv.cc.isClang "-std=c++11";

  nativeBuildInputs = [
    gdal # for gdal-config
    cython # required to build from a repo
  ];

  buildInputs = [
    gdal
  ] ++ lib.optionals stdenv.cc.isClang [ giflib ];

  propagatedBuildInputs = [
    attrs
    certifi
    click
    cligj
    click-plugins
    six
    munch
    pytz
  ] ++ lib.optional (!isPy3k) enum34;

  checkInputs = [
    pytestCheckHook
    boto3
  ] ++ lib.optional (pythonOlder "3.4") mock;

  preCheck = ''
    rm -r fiona # prevent importing local fiona
    # disable gdal deprecation warnings
    export GDAL_ENABLE_DEPRECATED_DRIVER_GTM=YES
  '';

  disabledTests = [
    # Some tests access network, others test packaging
    "http" "https" "wheel"
    # https://github.com/Toblerity/Fiona/issues/1164
    "test_no_append_driver_cannot_append"
  ];

  meta = with lib; {
    description = "OGR's neat, nimble, no-nonsense API for Python";
    homepage = "https://fiona.readthedocs.io/";
    license = licenses.bsd3;
    maintainers = with maintainers; [ knedlsepp ];
  };
}
