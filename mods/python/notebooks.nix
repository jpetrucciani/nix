final: prev: with prev; {
  ipyaggrid = buildPythonPackage
    rec {
      pname = "ipyaggrid";
      version = "0.4.0";
      format = "pyproject";

      src = fetchPypi {
        inherit pname version;
        hash = "sha256-unwV+xjQ8X8pjb/IK1DRJ4Ks9SzsDT9+aWqTgc8+XQM=";
      };

      nativeBuildInputs = [
        jupyter-packaging
        jupyterlab
        setuptools
        wheel
      ];

      propagatedBuildInputs = [
        ipywidgets
        pandas
        simplejson
      ];

      pythonImportsCheck = [ "ipyaggrid" ];

      meta = with lib; {
        description = "Jupyter widget - ag-grid in the notebook";
        homepage = "https://gitlab.com/DGothrek/ipyaggrid";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  xalglib = buildPythonPackage rec {
    pname = "xalglib";
    version = "3.16.0";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-n1hqnFwqm6mf75grehqOBbp589GtPXkZOeCVhrME4gM=";
    };

    pythonImportsCheck = [ "xalglib" ];

    meta = with lib; {
      description = "ALGLIB is a cross-platform numerical analysis and data processing library";
      homepage = "https://www.alglib.net/";
      license = with licenses; [ ];
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
