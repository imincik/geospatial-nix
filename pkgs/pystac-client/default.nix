{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pytestCheckHook,
  pythonOlder,

  pystac,
  pytest-benchmark,
  pytest-console-scripts,
  pytest-mock,
  pytest-recording,
  python-dateutil,
  requests,
  requests-mock,
  setuptools,
}:

buildPythonPackage rec {
  pname = "pystac-client";
  version = "0.8.3";
  pyproject = true;
  disabled = pythonOlder "3.9";

  src = fetchFromGitHub {
    owner = "stac-utils";
    repo = "pystac-client";
    rev = "v${version}";
    hash = "sha256-tzfpvNtj+KkKjA75En+OwxYQWGzxHLACLkzWT2j/ThU=";
  };

  build-system = [ setuptools ];

  propagatedBuildInputs = [
    pystac
    python-dateutil
    requests
  ];

  nativeCheckInputs = [
    pytest-benchmark
    pytestCheckHook
    pytest-console-scripts
    pytest-mock
    pytest-recording
    requests-mock
  ];

  disabledTests = [
    # tests are accessing network
    "test_collections_are_clients"
    "test_fallback_strategy"
    "test_from_file"
    "test_get_item"
    "test_get_items"
    "test_get_items_with_ids"
    "test_get_item_with_item_search"
    "test_get_queryables"
    "test_get_queryables"
    "test_get_queryables_collections"
    "test_instance"
    "test_instance"
    "test_intersects"
    "test_item_search"
    "test_links"
    "test_matched_not_available"
    "test_non_recursion_on_fallback"
    "test_request_input"
    "test_search_max_items_unlimited_default"
    "test_signing"
    "test_sign_with_return_warns"
    "test_str_input"
    "test_timeout_smoke_test"
  ];

  pythonImportsCheck = [ "pystac_client" ];

  meta = {
    description = "A Python client for working with STAC Catalogs and APIs";
    homepage = "https://github.com/stac-utils/pystac-client";
    license = lib.licenses.asl20;
    maintainers = lib.teams.geospatial.members;
  };
}
