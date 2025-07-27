final: prev:
let
  inherit (final) buildPythonPackage fetchPypi setuptools;
  inherit (final.lib) maintainers;
in
{
  types-cachetools = buildPythonPackage rec {
    pname = "types-cachetools";
    version = "5.3.0.6";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-WV8DQtJGyLpTT1p2LPTC9g7LYegAK4sid/1c95HU6FE=";
    };

    pythonImportsCheck = [ "cachetools-stubs" ];

    meta = {
      description = "Typing stubs for cachetools";
      homepage = "https://pypi.org/project/types-cachetools/";
      license = [ ];
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  types-croniter = buildPythonPackage rec {
    pname = "types-croniter";
    version = "6.0.0.20250626";
    format = "setuptools";

    src = fetchPypi {
      inherit version;
      pname = "types_croniter";
      hash = "sha256-wyJDsW1N+nyZiaXq3GdiRZ0JPd7QI/PDY/3ua5ZXinc=";
    };

    pythonImportsCheck = [ "croniter-stubs" ];

    meta = {
      description = "Typing stubs for croniter";
      homepage = "https://pypi.org/project/types-croniter/";
      license = [ ];
      maintainers = [ ];
    };
  };
}
