final: prev: with prev; rec {
  dataframe-image =
    let
      tex = pkgs.texlive.combine {
        inherit (pkgs.texlive) scheme-small latex-bin;
      };
    in
    buildPythonPackage rec {
      pname = "dataframe-image";
      version = "0.1.11";
      format = "setuptools";

      src = pkgs.fetchFromGitHub {
        owner = "dexplo";
        repo = "dataframe_image";
        rev = "refs/tags/v${version}";
        hash = "sha256-XxoUooMtpprBfVURvtAMwducVrd2yQxkpbkp9ziMBag=";
      };

      postPatch = ''
        substituteInPlace ./setup.py \
          --replace "use_scm_version=True," 'version="${version}",' \
          --replace 'setup_requires=["setuptools_scm"],' ""
      '';

      propagatedBuildInputs = [
        aiohttp
        beautifulsoup4
        cssutils
        html2image
        lxml
        matplotlib
        mistune
        nbconvert
        packaging
        pandas
        pillow
        requests
        tex
      ];

      nativeCheckInputs = [
        pytestCheckHook
        tex
      ];

      doCheck = false;

      pythonImportsCheck = [ "dataframe_image" ];

      meta = with lib; {
        description = "Embed pandas DataFrames as images in pdf and markdown files when converting from Jupyter Notebooks";
        homepage = "https://github.com/dexplo/dataframe_image";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  html2image = buildPythonPackage rec {
    pname = "html2image";
    version = "2.0.3";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-/WxrhnwbHrzasls4R/HdInHhHBzduLWxGwmyXgmx8dA=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    postPatch = ''
      substituteInPlace ./pyproject.toml --replace "poetry.masonry" "poetry.core.masonry"
    '';

    pythonImportsCheck = [ "html2image" ];

    meta = with lib; {
      description = "Generate images from URLs and from HTML+CSS strings or files";
      homepage = "https://github.com/vgalin/html2image";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

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
