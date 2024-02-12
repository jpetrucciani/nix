final: prev:
let
  inherit (final) buildPythonPackage fetchPypi;
  inherit (final.lib) licenses maintainers;
  inherit (final.pkgs) fetchFromGitHub;
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

    propagatedBuildInputs = with final; [
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

    propagatedBuildInputs = with final; [
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

    src = final.pkgs.fetchFromGitHub {
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

    propagatedBuildInputs = with final; [
      numba
      pandas
      py-lets-be-quickly-rational
      scipy
      simplejson
    ];

    nativeCheckInputs = with final; [
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

    src = final.pkgs.fetchFromGitHub {
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

    propagatedBuildInputs = with final; [
      numba
      numpy
      pandas
      py-lets-be-quickly-rational
      py-vollib
      scipy
    ];

    nativeCheckInputs = with final; [
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

    propagatedBuildInputs = with final; [
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

    propagatedBuildInputs = with final; [
      numpy
      pandas
      pandas-datareader
      scipy
    ];

    nativeCheckInputs = with final; [
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

    propagatedBuildInputs = with final; [
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

    propagatedBuildInputs = with final; [
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

    nativeCheckInputs = with final; [
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

      propagatedBuildInputs = with final; [
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

      nativeCheckInputs = with final; [
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
      export C_INCLUDE_PATH="./libindicators:${final.pkgs.numpy}/${final.python.sitePackages}/numpy/core/include"
      cythonize --inplace tulipy/lib/__init__.pyx
    '';

    nativeBuildInputs = with final; [
      cython
      numpy
      setuptools
      wheel
    ];

    propagatedBuildInputs = with final; [
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

      propagatedBuildInputs = with final; [
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

      nativeCheckInputs = with final; [
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

  statsforecast = buildPythonPackage rec {
    pname = "statsforecast";
    version = "1.6.0";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-23PsIbyB8k1eItNQiwoghKRRFxmyQKkigj2yg9uhLFI=";
    };

    nativeBuildInputs = with final; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with final; [
      fugue
      matplotlib
      numba
      numpy
      pandas
      polars
      scipy
      statsmodels
      tqdm
    ];

    passthru.optional-dependencies = with final; {
      dask = [
        fugue
      ];
      dev = [
        black
        datasetsforecast
        flake8
        fugue
        matplotlib
        mypy
        nbdev
        pmdarima
        prophet
        protobuf
        ray
        scikit-learn
        supersmoother
      ];
      plotly = [
        plotly
        plotly-resampler
      ];
      ray = [
        fugue
        protobuf
      ];
      spark = [
        fugue
      ];
    };

    pythonImportsCheck = [ "statsforecast" ];

    meta = {
      description = "Time series forecasting suite using statistical models";
      homepage = "https://pypi.org/project/statsforecast/";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  pandera = buildPythonPackage rec {
    pname = "pandera";
    version = "0.17.2";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-Z1FZhPhVuhTRJEP4k7X/kK5nlvYT1fPfQ6utQGpIw3M=";
    };

    nativeBuildInputs = with final; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with final; [
      multimethod
      numpy
      packaging
      pandas
      pydantic
      typeguard
      typing-extensions
      typing-inspect
      wrapt
    ];

    passthru.optional-dependencies = with final; {
      all = [
        black
        dask
        fastapi
        frictionless
        geopandas
        hypothesis
        modin
        pandas-stubs
        pyspark
        pyyaml
        ray
        scipy
        shapely
      ];
      dask = [
        dask
      ];
      fastapi = [
        fastapi
      ];
      geopandas = [
        geopandas
        shapely
      ];
      hypotheses = [
        scipy
      ];
      io = [
        black
        frictionless
        pyyaml
      ];
      modin = [
        dask
        modin
        ray
      ];
      modin-dask = [
        dask
        modin
      ];
      modin-ray = [
        modin
        ray
      ];
      mypy = [
        pandas-stubs
      ];
      pyspark = [
        pyspark
      ];
      strategies = [
        hypothesis
      ];
    };

    pythonImportsCheck = [ "pandera" ];

    meta = {
      description = "A light-weight and flexible data validation and testing tool for statistical data objects";
      homepage = "https://pypi.org/project/pandera/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  ffn = buildPythonPackage rec {
    pname = "ffn";
    version = "1.0.1";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "pmorissette";
      repo = "ffn";
      rev = "v${version}";
      hash = "sha256-ynl3y5ZeuZxTybEJ9P/z3VDlqwmhQUIMUcYe+eihl+o=";
    };

    nativeBuildInputs = with final; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with final; [
      decorator
      matplotlib
      numpy
      pandas
      pandas-datareader
      scikit-learn
      scipy
      tabulate
      yfinance
    ];

    passthru.optional-dependencies = with final; {
      dev = [
        build
        pytest
        pytest-cov
        ruff
        wheel
      ];
      test = [
        pytest
        pytest-cov
      ];
    };

    pythonImportsCheck = [ "ffn" ];

    meta = {
      description = "Ffn - a financial function library for Python";
      homepage = "https://github.com/pmorissette/ffn";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
