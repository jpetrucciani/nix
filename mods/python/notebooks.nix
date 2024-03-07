final: prev:
let
  inherit (prev) buildPythonPackage fetchPypi;
  inherit (prev) poetry-core pytestCheckHook;
  inherit (prev.lib) licenses maintainers;
  inherit (prev.pkgs) fetchFromGitHub texlive;
in
rec {
  dataframe-image =
    let
      tex = texlive.combine {
        inherit (texlive) scheme-small latex-bin;
      };
    in
    buildPythonPackage rec {
      pname = "dataframe-image";
      version = "0.1.11";
      format = "setuptools";

      src = fetchFromGitHub {
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

      propagatedBuildInputs = with prev; [
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

      meta = {
        description = "Embed pandas DataFrames as images in pdf and markdown files when converting from Jupyter Notebooks";
        homepage = "https://github.com/dexplo/dataframe_image";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  html2image = buildPythonPackage rec {
    pname = "html2image";
    version = "2.0.3";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-/WxrhnwbHrzasls4R/HdInHhHBzduLWxGwmyXgmx8dA=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    postPatch = ''
      sed -i -E 's#(poetry)>=0.12#\1-core#g' ./pyproject.toml
      substituteInPlace ./pyproject.toml --replace "poetry.masonry" "poetry.core.masonry"
    '';

    pythonImportsCheck = [ "html2image" ];

    meta = {
      description = "Generate images from URLs and from HTML+CSS strings or files";
      homepage = "https://github.com/vgalin/html2image";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  ipyaggrid = buildPythonPackage rec {
    pname = "ipyaggrid";
    version = "0.4.0";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-unwV+xjQ8X8pjb/IK1DRJ4Ks9SzsDT9+aWqTgc8+XQM=";
    };
    postPatch = ''
      sed -i -E 's#(requires =).*#\1["jupyterlab"]#g' ./pyproject.toml
    '';

    nativeBuildInputs = with prev; [
      jupyter-packaging
      jupyterlab
      setuptools
      wheel
    ];

    propagatedBuildInputs = with prev; [
      ipywidgets
      pandas
      simplejson
    ];

    pythonImportsCheck = [ "ipyaggrid" ];

    meta = {
      description = "Jupyter widget - ag-grid in the notebook";
      homepage = "https://github.com/widgetti/ipyaggrid";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  jupyterlab-code-formatter = buildPythonPackage rec {
    pname = "jupyterlab-code-formatter";
    version = "1.6.1";
    pyproject = true;

    src = fetchPypi {
      pname = "jupyterlab_code_formatter";
      inherit version;
      hash = "sha256-3fCEODKSzs7dyq4EP0xiuT0nqFhQV4ooD4/e2aG5OjI=";
    };
    postPatch = ''
      sed -i -E 's#(requires =).*#\1["jupyterlab"]#g' ./pyproject.toml
    '';

    nativeBuildInputs = with prev; [
      jupyter-packaging
      jupyterlab
      setuptools
      wheel
    ];

    pythonImportsCheck = [ "jupyterlab_code_formatter" ];

    meta = {
      description = "Code formatter for JupyterLab";
      homepage = "https://github.com/ryantam626/jupyterlab_code_formatter";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  jupyterlab-execute-time =
    let
      pname = "jupyterlab-execute-time";
      version = "2.3.1";
      format = "wheel";
      src = fetchPypi {
        inherit version;
        pname = "jupyterlab_execute_time";
        format = "wheel";
        python = "py3";
        dist = "py3";
        platform = "any";
        hash = "sha256-l10U+f6VyBaJrXTj84XaDBqDqdHm4J6dwC9ms60Fml4=";
      };
    in
    buildPythonPackage {
      inherit pname src version format;

      nativeBuildInputs = with prev; [
        jupyter-packaging
        jupyterlab
      ];

      propagatedBuildInputs = with prev; [
        jupyter-server
      ];

      pythonImportsCheck = [ "jupyterlab_execute_time" ];

      meta = {
        description = "Display cell timings in Jupyter Lab";
        homepage = "https://github.com/deshaw/jupyterlab-execute-time";
        license = licenses.bsd3;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  jupyterlab-templates =
    let
      pname = "jupyterlab-templates";
      version = "0.4.1";
      format = "wheel";
      src = fetchPypi {
        inherit version;
        pname = "jupyterlab_templates";
        format = "wheel";
        python = "py3";
        dist = "py3";
        platform = "any";
        hash = "sha256-BUURbe7BQCHH0hmygppbsL7+mqju9XV8JSSxntrVd7U=";
      };
    in
    buildPythonPackage {
      inherit pname src version format;

      nativeBuildInputs = with prev; [
        jupyter-packaging
        jupyterlab
      ];

      propagatedBuildInputs = with prev; [
        jupyter-server
      ];

      pythonImportsCheck = [ "jupyterlab_templates" ];

      meta = {
        description = "Support for jupyter notebook templates in jupyterlab";
        homepage = "https://github.com/finos/jupyterlab_templates";
        license = licenses.asl20;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  voila =
    let
      pname = "voila";
      version = "0.5.4";
      format = "wheel";
      src = fetchPypi {
        inherit pname version;
        format = "wheel";
        python = "py3";
        dist = "py3";
        platform = "any";
        hash = "sha256-98rEqUgh3kDSg0Rz5tO/0gAJJ0B8U4VIaWZDSi4fbZg=";
      };
    in
    buildPythonPackage {
      inherit pname src version format;

      nativeBuildInputs = with prev; [
        hatchling
        hatch-jupyter-builder
        jupyter-core
        jupyterlab
      ];

      propagatedBuildInputs = with prev; [
        jupyter-client
        jupyter-core
        jupyter-server
        jupyterlab_server
        nbclient
        nbconvert
        traitlets
        websockets
      ];

      passthru.optional-dependencies = with prev; {
        dev = [
          black
          hatch
          jupyter-releaser
          pre-commit
        ];
        test = [
          ipykernel
          ipywidgets
          matplotlib
          mock
          numpy
          pandas
          papermill
          pytest
          pytest-tornasync
        ];
      };

      pythonImportsCheck = [ "voila" ];

      meta = {
        description = "Turn Jupyter notebooks into standalone web applications";
        homepage = "https://github.com/voila-dashboards/voila";
        license = licenses.bsd3;
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

    meta = {
      description = "ALGLIB is a cross-platform numerical analysis and data processing library";
      homepage = "https://www.alglib.net/";
      license = with licenses; [ ];
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
