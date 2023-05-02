final: prev: with prev; rec {
  py-lets-be-quickly-rational = buildPythonPackage rec {
    pname = "py-lets-be-quickly-rational";
    version = "1.0.1";
    format = "setuptools";

    src = fetchPypi {
      inherit version;
      pname = "py_lets_be_quickly_rational";
      hash = "sha256-NjT3q9DdAsRLnATNYGszn4A7cjBZ1/xflUD7Zgk9wqE=";
    };

    propagatedBuildInputs = [
      numba
      numpy
    ];

    pythonImportsCheck = [ "py_lets_be_quickly_rational" ];

    meta = with lib; {
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

    propagatedBuildInputs = [
      numba
      numpy
    ];

    pythonImportsCheck = [ "py_lets_be_rational" ];

    meta = with lib; {
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

    propagatedBuildInputs = [
      numba
      pandas
      py-lets-be-quickly-rational
      scipy
      simplejson
    ];

    nativeCheckInputs = [
      pytestCheckHook
    ];

    NUMBA_CACHE_DIR = "./cache";

    pythonImportsCheck = [ "py_vollib" ];

    meta = with lib; {
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

    propagatedBuildInputs = [
      numba
      numpy
      pandas
      py-lets-be-quickly-rational
      py-vollib
      scipy
    ];

    nativeCheckInputs = [
      pytestCheckHook
    ];

    NUMBA_CACHE_DIR = "./cache";

    pythonImportsCheck = [ "py_vollib_vectorized" ];

    meta = with lib; {
      description = "A fast, vectorized approach to calculating Implied Volatility and Greeks using the Black, Black-Scholes and Black-Scholes-Merton pricing";
      homepage = "https://github.com/marcdemers/py_vollib_vectorized";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
