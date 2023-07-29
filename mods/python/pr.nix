# this overlay is for python packages that i've tried to open PRs to nixpkgs for
final: prev: with prev; rec {
  boddle = buildPythonPackage rec {
    pname = "boddle";
    version = "0.2.9";

    src = fetchPypi {
      inherit pname version;
      sha256 = "0p3bfb2n0v3w27f5ji0na5pchjprklalddxsjd1bdbdi585naldn";
    };

    propagatedBuildInputs = [ bottle ];

    meta = with lib; {
      description = "Unit testing tool for Python's bottle library";
      homepage = "https://github.com/keredson/boddle";
      license = licenses.lgpl21Only;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  procrastinate = buildPythonPackage rec {
    pname = "procrastinate";
    version = "0.27.0";

    format = "pyproject";
    src = pkgs.fetchFromGitHub {
      owner = "procrastinate-org";
      repo = pname;
      rev = version;
      sha256 = "sha256-+Nv3ssQ7IBhtoMT4AfJ4XCQolEa/ZG/nSxEbiBwiAJk=";
    };

    preBuild = ''
      substituteInPlace ./pyproject.toml --replace 'psycopg2-binary' 'psycopg2'
      substituteInPlace ./poetry.lock --replace 'psycopg2-binary' 'psycopg2'
    '';

    propagatedBuildInputs = [
      aiopg
      attrs
      click
      croniter
      poetry-core
      psycopg2
      python-dateutil
    ];

    meta = with lib; {
      description = "Postgres-based distributed task processing library";
      homepage = "https://github.com/procrastinate-org/procrastinate";
      changelog = "https://procrastinate.readthedocs.io/en/latest/changelog.html";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  # requirements for other packages
  radon = buildPythonPackage rec {
    pname = "radon";
    version = "5.1.0";

    src = fetchPypi {
      inherit pname version;
      sha256 = "1vmf56zsf3paa1jadjcjghiv2kxwiismyayq42ggnqpqwm98f7fb";
    };

    propagatedBuildInputs = [ mando colorama future ];

    doCheck = false;

    meta = with lib; {
      description = "Code Metrics in Python";
      homepage = "https://radon.readthedocs.org/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  mando = buildPythonPackage rec {
    pname = "mando";
    version = "0.6.4";

    src = fetchPypi {
      inherit pname version;
      sha256 = "0q6rl085q1hw1wic52pqfndr0x3nirbxnhqj9akdm5zhq2fv3zkr";
    };

    propagatedBuildInputs = [ six ];

    doCheck = false;

    meta = with lib; {
      description = "Create Python CLI apps with little to no effort at all";
      homepage = "https://mando.readthedocs.org/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  lox = buildPythonPackage rec {
    pname = "lox";
    version = "0.11.0";
    disabled = pythonOlder "3.7";

    src = pkgs.fetchFromGitHub {
      owner = "BrianPugh";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-kXfFRIFI1OcbDc1LujbFo/Iqg7pgwtXLkIcIFA9nehs=";
    };

    # patch out pytest-runner, and invalid pytest args
    preBuild = ''
      sed -i '/pytest-runner/d' ./setup.py
      sed -i '/collect_ignore/d' ./setup.cfg
    '';

    outputs = [
      "out"
      "doc"
    ];

    nativeBuildInputs = [
      sphinxHook
      sphinx-rtd-theme
    ];

    checkInputs = [
      pytestCheckHook
      pytest-benchmark
      pytest-mock
    ];

    propagatedBuildInputs = [
      pathos
      tqdm
    ];

    pythonImportsCheck = [
      "lox"
    ];

    meta = with lib; {
      description = "Threading and Multiprocessing made easy";
      homepage = "https://github.com/BrianPugh/lox";
      changelog = "https://github.com/BrianPugh/lox/releases/tag/v${version}";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  looker-sdk = buildPythonPackage rec {
    pname = "looker-sdk";
    version = "22.20.0";
    disabled = pythonOlder "3.7";

    src = pkgs.fetchFromGitHub {
      owner = "looker-open-source";
      repo = "sdk-codegen";
      rev = "sdk-v${version}";
      hash = "sha256-S5s88FequBLbgz+zbEcBFi/N2pCgC0zdwyrcd7SP+no=";
    };
    sourceRoot = "source/python";

    propagatedBuildInputs = [
      attrs
      cattrs
      exceptiongroup
      requests
      typing-extensions
    ];

    pythonImportsCheck = [
      "looker_sdk"
    ];

    checkInputs = [
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

    meta = with lib; {
      description = "Looker REST API SDK for Python";
      homepage = "https://github.com/looker-open-source/sdk-codegen/tree/main/python";
      changelog = "https://github.com/looker-open-source/sdk-codegen/blob/main/python/CHANGELOG.md";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
