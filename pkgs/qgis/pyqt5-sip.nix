# FIX sip and pyqt5_sip compatibility. See: https://github.com/NixOS/nixpkgs/issues/273561
# Remove this fix in NixOS 24.05.

{ lib
, buildPythonPackage
, fetchPypi
}:

buildPythonPackage rec {
  pname = "pyqt5-sip";
  version = "12.13.0";

  src = fetchPypi {
    pname = "PyQt5_sip";
    inherit version;
    hash = "sha256-fzIdr4S5ydvKYbgOHvN72v/A6TMS7a4s19oluVOXHZE=";
  };

  # There is no test code and the check phase fails with:
  # > error: could not create 'PyQt5/sip.cpython-38-x86_64-linux-gnu.so': No such file or directory
  doCheck = false;
  pythonImportsCheck = ["PyQt5.sip"];

  meta = with lib; {
    description = "Python bindings for Qt5";
    homepage    = "https://www.riverbankcomputing.com/software/sip/";
    license     = licenses.gpl3Only;
    platforms   = platforms.mesaPlatforms;
    maintainers = with maintainers; [ sander ];
  };
}
