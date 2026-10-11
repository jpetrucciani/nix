# this overlay is for python packages that i've tried to open PRs to nixpkgs for
final: prev:
let
  inherit (prev) buildPythonPackage fetchPypi pythonOlder;
  inherit (prev.lib) licenses maintainers;
  inherit (prev.pkgs) fetchFromGitHub;
in
rec {
  boddle = buildPythonPackage rec {
    pname = "boddle";
    version = "0.2.9";
    pyproject = true;
    build-system = with prev; [ setuptools ];

    src = fetchPypi {
      inherit pname version;
      sha256 = "0p3bfb2n0v3w27f5ji0na5pchjprklalddxsjd1bdbdi585naldn";
    };

    propagatedBuildInputs = with prev; [ bottle ];

    meta = {
      description = "Unit testing tool for Python's bottle library";
      homepage = "https://github.com/keredson/boddle";
      license = licenses.lgpl21Only;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  procrastinate = buildPythonPackage rec {
    pname = "procrastinate";
    version = "0.27.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "procrastinate-org";
      repo = pname;
      rev = version;
      sha256 = "sha256-+Nv3ssQ7IBhtoMT4AfJ4XCQolEa/ZG/nSxEbiBwiAJk=";
    };

    preBuild = ''
      substituteInPlace ./pyproject.toml --replace 'psycopg2-binary' 'psycopg2'
      substituteInPlace ./poetry.lock --replace 'psycopg2-binary' 'psycopg2'
    '';

    propagatedBuildInputs = with prev; [
      aiopg
      attrs
      click
      croniter
      poetry-core
      psycopg2
      python-dateutil
    ];

    meta = {
      description = "Postgres-based distributed task processing library";
      homepage = "https://github.com/procrastinate-org/procrastinate";
      changelog = "https://procrastinate.readthedocs.io/en/latest/changelog.html";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  looker-sdk = buildPythonPackage rec {
    pname = "looker-sdk";
    version = "24.4.0";
    pyproject = true;
    build-system = with prev; [ setuptools ];
    disabled = pythonOlder "3.7";

    src = fetchFromGitHub {
      owner = "looker-open-source";
      repo = "sdk-codegen";
      rev = "sdk-v${version}";
      hash = "sha256-n1PajH2uskbFQe4VKkJY2MB3MaCFKCBsGROw3NRPJdk=";
    };
    sourceRoot = "source/python";

    propagatedBuildInputs = with prev; [
      attrs
      cattrs
      exceptiongroup
      requests
      typing-extensions
    ];

    pythonImportsCheck = [
      "looker_sdk"
    ];

    checkInputs = with prev; [
      pytestCheckHook
      pillow
      pytest-mock
      pyyaml
    ];

    # disable tests that attempt to actually communicate with the api
    disabledTestPaths = [
      "tests/integration/test_methods.py"
      "tests/integration/test_netrc.py"
      "tests/rtl/test_api_methods.py"
    ];

    meta = {
      description = "Looker REST API SDK for Python";
      homepage = "https://github.com/looker-open-source/sdk-codegen/tree/main/python";
      changelog = "https://github.com/looker-open-source/sdk-codegen/blob/main/python/CHANGELOG.md";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
