final: prev:
let
  inherit (prev) buildPythonPackage fetchPypi;
  inherit (prev.lib) licenses maintainers;
  inherit (prev.pkgs) fetchFromGitHub;
in
rec {
  py-lets-be-quickly-rational = buildPythonPackage rec {
    pname = "py-lets-be-quickly-rational";
    version = "1.0.1";
    format = "setuptools";

    src = fetchPypi {
      inherit version;
      pname = "py_lets_be_quickly_rational";
      hash = "sha256-NjT3q9DdAsRLnATNYGszn4A7cjBZ1/xflUD7Zgk9wqE=";
    };

    propagatedBuildInputs = with prev; [
      numba
      numpy
    ];

    pythonImportsCheck = [ "py_lets_be_quickly_rational" ];

    meta = {
      description = "Numba accelerated python library to calculate various black scholes equations";
      homepage = "https://github.com/tmcnitt/py_lets_be_quickly_rational";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  py-lets-be-rational = buildPythonPackage rec {
    pname = "py-lets-be-rational";
    version = "1.0.1";
    format = "setuptools";

    src = fetchPypi {
      inherit version;
      pname = "py_lets_be_rational";
      hash = "sha256-DgeIpBCeECpmbybWcnbA08L+uKBZ54g1SpDlZfLbDtI=";
    };

    propagatedBuildInputs = with prev; [
      numba
      numpy
    ];

    pythonImportsCheck = [ "py_lets_be_rational" ];

    meta = {
      description = "Pure python implementation of Peter Jaeckel's LetsBeRational";
      homepage = "https://pypi.org/project/py_lets_be_rational/1.0.1/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  py-vollib = buildPythonPackage {
    pname = "py-vollib";
    version = "1.0.1";
    format = "setuptools";

    src = prev.pkgs.fetchFromGitHub {
      owner = "vollib";
      repo = "py_vollib";
      rev = "f5f3a1ecec73c0ae98a5e5ec9f17a8e65a4dc476";
      hash = "sha256-ejxxWNw8JkJlgVbmDyUOQ4FdDNiXzMpLxFkPUUDIFH0=";
    };

    preBuild = ''
      mkdir -p ./cache
      sed -i -E -e 's#py_lets_be_rational#py_lets_be_quickly_rational#g' \
        setup.py \
        py_vollib/black_scholes_merton/__init__.py \
        py_vollib/black_scholes/implied_volatility.py \
        py_vollib/black/greeks/analytical.py \
        py_vollib/black_scholes/greeks/analytical.py \
        py_vollib/black_scholes_merton/greeks/analytical.py \
        py_vollib/black_scholes_merton/implied_volatility.py \
        py_vollib/black/__init__.py \
        py_vollib/black/implied_volatility.py
      sed -i -E -e 's#\.ix\[#\.loc\[#g' tests/test_utils.py
    '';

    propagatedBuildInputs = with prev; [
      numba
      pandas
      py-lets-be-quickly-rational
      scipy
      simplejson
    ];

    nativeCheckInputs = with prev; [
      pytestCheckHook
    ];

    NUMBA_CACHE_DIR = "./cache";

    pythonImportsCheck = [ "py_vollib" ];

    meta = {
      description = "";
      homepage = "https://vollib.org/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  py-vollib-vectorized = buildPythonPackage {
    pname = "py-vollib-vectorized";
    version = "0.1.1";
    format = "setuptools";

    src = prev.pkgs.fetchFromGitHub {
      owner = "marcdemers";
      repo = "py_vollib_vectorized";
      rev = "0c2519ff58e3caf2caee37ca37d878e6e5e1eefd";
      hash = "sha256-+tpSae8C3c9c9NuILhgXb1u5nIWhu0uoBrKdMM7DNqs=";
    };

    preBuild = ''
      mkdir -p ./cache
      sed -i -E -e 's#py_lets_be_rational#py_lets_be_quickly_rational#g' \
        setup.py \
        py_vollib_vectorized/_iv_models.py \
        py_vollib_vectorized/_model_calls.py \
        py_vollib_vectorized/util/greeks_helpers.py
      cp ./tests/test_data_py_vollib.json ./
      cp ./tests/fake_data.csv ./
    '';

    propagatedBuildInputs = with prev; [
      numba
      numpy
      pandas
      py-lets-be-quickly-rational
      py-vollib
      scipy
    ];

    nativeCheckInputs = with prev; [
      pytestCheckHook
    ];

    NUMBA_CACHE_DIR = "./cache";

    pythonImportsCheck = [ "py_vollib_vectorized" ];

    meta = {
      description = "A fast, vectorized approach to calculating Implied Volatility and Greeks using the Black, Black-Scholes and Black-Scholes-Merton pricing";
      homepage = "https://github.com/marcdemers/py_vollib_vectorized";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  swifter = buildPythonPackage rec {
    pname = "swifter";
    version = "1.3.4";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-Ysh6IMTfr805Q82EVeYU66EdA82k/6IEZbMur6Vx9L0=";
    };

    propagatedBuildInputs = with prev; [
      bleach
      cloudpickle
      dask
      ipywidgets
      parso
      ray
      tqdm
    ];

    doCheck = false;

    pythonImportsCheck = [ "swifter" ];

    meta = {
      description = "A package which efficiently applies any function to a pandas dataframe or series in the fastest available manner";
      homepage = "https://github.com/jmcarpenter2/swifter";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  empyrical = buildPythonPackage rec {
    pname = "empyrical";
    version = "0.5.5";
    format = "setuptools";

    src = fetchFromGitHub {
      owner = "quantopian";
      repo = pname;
      rev = "refs/tags/${version}";
      hash = "sha256-SrrJZXg8kVOc71whjcyWvZyiAwwpC0LDVhPjeeCjV7I=";
    };

    propagatedBuildInputs = with prev; [
      numpy
      pandas
      pandas-datareader
      scipy
    ];

    nativeCheckInputs = with prev; [
      pytestCheckHook
      parameterized
      flake8
    ];

    pythonImportsCheck = [ "empyrical" ];

    doCheck = false;

    meta = {
      description = "Empyrical is a Python library with performance and risk statistics commonly used in quantitative finance";
      homepage = "https://github.com/quantopian/empyrical";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  runipy = buildPythonPackage rec {
    pname = "runipy";
    version = "0.1.5";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-IC1rsZy3fiXfhwCxao+ZDx66kQjMelh7Mg62Is2uZ4k=";
    };

    propagatedBuildInputs = with prev; [
      ipykernel
      ipython
      jinja2
      nbconvert
      pygments
      pyzmq
    ];

    pythonImportsCheck = [ "runipy" ];

    doCheck = false;

    meta = {
      description = "Run IPython notebooks from the command line";
      homepage = "https://github.com/paulgb/runipy";
      license = licenses.bsd2;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  pyfolio = buildPythonPackage rec {
    pname = "pyfolio";
    version = "0.9.2";
    format = "setuptools";

    src = fetchFromGitHub {
      owner = "quantopian";
      repo = pname;
      rev = "refs/tags/${version}";
      hash = "sha256-Zeonx3W4Te3uv0sZ8yHxYbf5ImLozeyniG+LLxsHLhY=";
    };

    propagatedBuildInputs = with prev; [
      empyrical
      ipython
      matplotlib
      pandas
      pytz
      scikit-learn
      scipy
      seaborn
    ];

    pythonImportsCheck = [ "pyfolio" ];

    nativeCheckInputs = with prev; [
      pytestCheckHook
      nose
      parameterized
      runipy
    ];

    doCheck = false;

    meta = {
      description = "Pyfolio is a Python library for performance and risk analysis of financial portfolios";
      homepage = "https://github.com/quantopian/pyfolio";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  alpaca-trade-api =
    let
      version = "3.0.0";
    in
    buildPythonPackage {
      inherit version;
      pname = "alpaca-trade-api";
      format = "setuptools";

      src = fetchFromGitHub {
        owner = "alpacahq";
        repo = "alpaca-trade-api-python";
        rev = "refs/tags/v${version}";
        hash = "sha256-HcnYDLqyQ3QERX9FrZ5/MmCxxz3Ib4w/ExvgASDySXU=";
      };

      postPatch = let sed = "sed -i -E"; in ''
        ${sed} '/setup_requires/d' ./setup.py
        ${sed} \
          -e 's#(msgpack)==(1.0.3)#\1>=\2#g' \
          -e 's#(aiohttp)==(3.8.1)#\1>=\2#g' \
          ./requirements/requirements.txt
      '';

      propagatedBuildInputs = with prev; [
        aiohttp
        deprecation
        msgpack
        numpy
        pandas
        pyyaml
        requests
        urllib3
        websocket-client
        websockets
      ];

      nativeCheckInputs = with prev; [
        pytest-cov
        pytest-mock
        pytestCheckHook
        requests-mock
      ];

      pythonImportsCheck = [ "alpaca_trade_api" ];

      meta = {
        description = "Alpaca API python client";
        homepage = "https://github.com/alpacahq/alpaca-trade-api-python";
        license = licenses.asl20;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  newnewtulipy = buildPythonPackage {
    pname = "newnewtulipy";
    version = "0.4.6.5";
    format = "pyproject";

    src = fetchFromGitHub {
      owner = "blankly-finance";
      repo = "newnewtulipy";
      rev = "b26d594cf594e58776a923278cdd091ce2bba9cd";
      hash = "sha256-P5CX0JF6YjskO5v+5R1+FP+rAx1J7YZ0F6oljul7MJ4=";
    };

    preBuild = ''
      export C_INCLUDE_PATH="./libindicators:${prev.pkgs.numpy}/${prev.python.sitePackages}/numpy/core/include"
      cythonize --inplace tulipy/lib/__init__.pyx
    '';

    nativeBuildInputs = with prev; [
      cython
      numpy
      setuptools
      wheel
    ];

    propagatedBuildInputs = with prev; [
      numpy
    ];

    pythonImportsCheck = [ "tulipy" ];

    meta = {
      description = "Financial Technical Analysis Indicator Library";
      homepage = "https://github.com/blankly-finance/newnewtulipy";
      license = licenses.lgpl3Only;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  blankly =
    let
      pname = "blankly";
      version = "1.18.0-beta";
    in
    buildPythonPackage {
      inherit pname version;
      format = "setuptools";

      src = fetchFromGitHub {
        owner = "blankly-finance";
        repo = pname;
        rev = "refs/tags/v${version}";
        hash = "sha256-kvam39rRG9ZBNFfjhtX6jivA2H1BeBDS8dGalO7ub+k=";
      };

      propagatedBuildInputs = with prev; [
        alpaca-trade-api
        bokeh
        dateparser
        newnewtulipy
        numpy
        pandas
        python-binance
        questionary
        requests
        websocket-client
        yaspin
      ];

      pythonImportsCheck = [ "blankly" ];

      nativeCheckInputs = with prev; [
        pytestCheckHook
      ];

      # tests require credentials
      doCheck = false;

      meta = {
        description = "Rapidly build, backtest & deploy trading bots";
        homepage = "https://github.com/blankly-finance/blankly";
        license = with licenses; [ ];
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };
}
