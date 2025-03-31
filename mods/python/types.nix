final: prev:
let
  inherit (final) buildPythonPackage fetchPypi;
  inherit (final.lib) maintainers;
in
rec {
  boto3-stubs = buildPythonPackage rec {
    pname = "boto3-stubs";
    version = "1.20.35";

    src = fetchPypi {
      inherit pname version;
      sha256 = "1nnd8jjakbcfjsfwn0w7i8mkqj7zji7x2vzmgklbrh3hw10ig95p";
    };

    propagatedBuildInputs = [ botocore-stubs ];
    checkInputs = with final; [
      boto3
    ];
    pythonImportsCheck = [ "boto3-stubs" ];

    meta = {
      description =
        "Type annotations for boto3 1.20.35, generated by mypy-boto3-builder 6.3.1";
      homepage = "https://github.com/vemel/mypy_boto3_builder";
    };
  };

  botocore-stubs = buildPythonPackage rec {
    pname = "botocore-stubs";
    version = "1.24.6";

    src = fetchPypi {
      inherit pname version;
      sha256 = "093zsj2wk7xw89yvs7w88z9w3811vkpgfv4q3wk9j6gd6n3hr1pw";
    };

    pythonImportsCheck = [ "botocore-stubs" ];

    meta = {
      description =
        "Type annotations for botocore 1.24.6 generated with mypy-boto3-builder 7.1.2";
      homepage = "https://github.com/vemel/mypy_boto3_builder";
    };
  };

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
    version = "1.4.0.1";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-WCFojJO4dFALaGO4oWSo28Se/c7ZhdAMvd3AKbgQZ7g=";
    };

    pythonImportsCheck = [ "croniter-stubs" ];

    meta = {
      description = "Typing stubs for croniter";
      homepage = "https://pypi.org/project/types-croniter/";
      license = [ ];
      maintainers = [ ];
    };
  };

  types-python-dateutil = buildPythonPackage rec {
    pname = "types-python-dateutil";
    version = "2.8.19.14";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-H08QrJi7ixat6dvuNRjZrOAXgh2UsFekJbBp+DRzf0s=";
    };

    pythonImportsCheck = [ "dateutil-stubs" ];

    meta = {
      description = "Typing stubs for python-dateutil";
      homepage = "https://pypi.org/project/types-python-dateutil/";
      license = [ ];
      maintainers = [ ];
    };
  };
}
