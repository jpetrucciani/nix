final: prev:
let
  inherit (prev) buildPythonPackage fetchPypi;
in
{
  decompyle3 = buildPythonPackage rec {
    pname = "decompyle3";
    version = "3.9.0";
    pyproject = true;
    build-system = with prev; [ setuptools ];

    src = fetchPypi {
      inherit pname version;
      sha256 = "0c55zm1d7bi1lpvw1z0vvdvfkaqhfkcf40494khd2kcv23wcnji2";
    };

    propagatedBuildInputs = with prev; [ click spark-parser xdis ];

    doCheck = false;

    meta = {
      description = "Python cross-version byte-code decompiler";
      homepage = "https://github.com/rocky/python-decompile3/";
    };
  };

  pyrasite = buildPythonPackage rec {
    pname = "pyrasite";
    version = "2.0";
    pyproject = true;
    build-system = with prev; [ setuptools ];

    src = fetchPypi {
      inherit pname version;
      sha256 = "1kvc3xqdxn5y1jk554kaa83wi9xvkf70mil8csj0179p0ima7xz5";
    };

    doCheck = false;
    pythonImportsCheck = [ "pyrasite" ];

    meta = {
      description = "Inject code into a running Python process";
      homepage = "http://pyrasite.com";
    };
  };
}
