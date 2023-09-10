final: prev:
let
  inherit (prev) buildPythonPackage fetchPypi;
  inherit (prev.lib) licenses maintainers;
  inherit (prev.pkgs) fetchFromGitHub;
in
rec {
  autogluon-common = buildPythonPackage rec {
    pname = "autogluon-common";
    version = "0.8.2";
    format = "setuptools";

    src = fetchFromGitHub {
      owner = "autogluon";
      repo = "autogluon";
      rev = "refs/tags/v${version}";
      hash = "sha256-AjV/SY4wyAqGPba/SXtRDBXQ66gZZgVbQQG3GfAG8hk=";
    };

    preBuild = ''
      cd ./common
      sed -i -E '/install_requires=/d' ./setup.py
    '';

    propagatedBuildInputs = with prev; [
      boto3
      numpy
      pandas
      psutil
      setuptools
    ];

    passthru.optional-dependencies = with prev; {
      tests = [
        pytest
        pytest-mypy
        types-requests
        types-setuptools
      ];
    };

    pythonImportsCheck = [ "autogluon.common" ];

    meta = {
      description = "AutoML for Image, Text, and Tabular Data";
      homepage = "https://pypi.org/project/autogluon-common";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  autogluon-core = buildPythonPackage rec {
    pname = "autogluon-core";
    version = "0.8.2";
    format = "setuptools";

    src = fetchFromGitHub {
      owner = "autogluon";
      repo = "autogluon";
      rev = "refs/tags/v${version}";
      hash = "sha256-AjV/SY4wyAqGPba/SXtRDBXQ66gZZgVbQQG3GfAG8hk=";
    };

    preBuild = ''
      cd ./core
      sed -i -E '/install_requires=/d' ./setup.py
    '';

    propagatedBuildInputs = with prev; [
      autogluon-common
      boto3
      matplotlib
      networkx
      numpy
      pandas
      requests
      scikit-learn
      scipy
      tqdm
    ];

    passthru.optional-dependencies = with prev; {
      all = [
        grpcio
        hyperopt
        pydantic
        ray
      ];
      ray = [
        grpcio
        pydantic
        ray
      ];
      raytune = [
        hyperopt
        ray
      ];
      tests = [
        pytest
        pytest-mypy
        types-requests
        types-setuptools
      ];
    };

    pythonImportsCheck = [ "autogluon.core" ];

    meta = {
      description = "AutoML for Image, Text, and Tabular Data";
      homepage = "https://pypi.org/project/autogluon-core";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  autogluon-features = buildPythonPackage rec {
    pname = "autogluon-features";
    version = "0.8.2";
    format = "setuptools";

    src = fetchFromGitHub {
      owner = "autogluon";
      repo = "autogluon";
      rev = "refs/tags/v${version}";
      hash = "sha256-AjV/SY4wyAqGPba/SXtRDBXQ66gZZgVbQQG3GfAG8hk=";
    };

    preBuild = ''
      cd ./features
      sed -i -E '/install_requires=/d' ./setup.py
    '';

    propagatedBuildInputs = with prev; [
      autogluon-common
      numpy
      pandas
      scikit-learn
    ];

    pythonImportsCheck = [ "autogluon.features" ];

    meta = {
      description = "AutoML for Image, Text, and Tabular Data";
      homepage = "https://pypi.org/project/autogluon-features";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  autogluon-multimodal = buildPythonPackage rec {
    pname = "autogluon-multimodal";
    version = "0.8.2";
    format = "setuptools";

    src = fetchFromGitHub {
      owner = "autogluon";
      repo = "autogluon";
      rev = "refs/tags/v${version}";
      hash = "sha256-AjV/SY4wyAqGPba/SXtRDBXQ66gZZgVbQQG3GfAG8hk=";
    };

    preBuild = ''
      cd ./multimodal
      sed -i -E '/install_requires=/d' ./setup.py
    '';

    propagatedBuildInputs = with prev; [
      accelerate
      autogluon-common
      autogluon-core
      autogluon-features
      boto3
      defusedxml
      evaluate
      jinja2
      jsonschema
      nlpaug
      nltk
      nptyping
      numpy
      omegaconf
      # openmim
      pandas
      pillow
      pytesseract
      pytorch-lightning
      pytorch-metric-learning
      requests
      scikit-image
      scikit-learn
      scipy
      seqeval
      tensorboard
      text-unidecode
      timm
      torch
      torchmetrics
      torchvision
      tqdm
      transformers
    ];

    passthru.optional-dependencies = with prev; {
      pymupdf = [
        pymupdf
      ];
      tests = [
        black
        datasets
        isort
        onnx
        onnxruntime
        onnxruntime-gpu
        pymupdf
        tensorrt
      ];
    };

    pythonImportsCheck = [ "autogluon.multimodal" ];

    meta = {
      description = "AutoML for Image, Text, and Tabular Data";
      homepage = "https://pypi.org/project/autogluon-multimodal";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  autogluon-tabular = buildPythonPackage rec {
    pname = "autogluon-tabular";
    version = "0.8.2";
    format = "setuptools";

    src = fetchFromGitHub {
      owner = "autogluon";
      repo = "autogluon";
      rev = "refs/tags/v${version}";
      hash = "sha256-AjV/SY4wyAqGPba/SXtRDBXQ66gZZgVbQQG3GfAG8hk=";
    };

    preBuild = ''
      cd ./tabular
      sed -i -E '/install_requires=/d' ./setup.py
    '';

    propagatedBuildInputs = with prev; [
      autogluon-core
      autogluon-features
      networkx
      numpy
      pandas
      scikit-learn
      scipy
    ];

    passthru.optional-dependencies = with prev; {
      all = [
        autogluon-core
        catboost
        fastai
        lightgbm
        torch
        xgboost
      ];
      catboost = [
        catboost
      ];
      fastai = [
        fastai
        torch
      ];
      imodels = [
        imodels
      ];
      lightgbm = [
        lightgbm
      ];
      ray = [
        autogluon-core
      ];
      skex = [
        scikit-learn-intelex
      ];
      skl2onnx = [
        onnxruntime-gpu
        skl2onnx
      ];
      tabpfn = [
        tabpfn
      ];
      tests = [
        imodels
        onnxruntime-gpu
        skl2onnx
        tabpfn
        vowpalwabbit
      ];
      vowpalwabbit = [
        vowpalwabbit
      ];
      xgboost = [
        xgboost
      ];
    };

    pythonImportsCheck = [ "autogluon.tabular" ];

    meta = {
      description = "AutoML for Image, Text, and Tabular Data";
      homepage = "https://pypi.org/project/autogluon-tabular";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  autogluon-timeseries = buildPythonPackage rec {
    pname = "autogluon-timeseries";
    version = "0.8.2";
    format = "setuptools";

    src = fetchFromGitHub {
      owner = "autogluon";
      repo = "autogluon";
      rev = "refs/tags/v${version}";
      hash = "sha256-AjV/SY4wyAqGPba/SXtRDBXQ66gZZgVbQQG3GfAG8hk=";
    };

    preBuild = ''
      cd ./timeseries
      sed -i -E '/install_requires=/d' ./setup.py
    '';

    propagatedBuildInputs = with prev; [
      autogluon-common
      autogluon-core
      autogluon-tabular
      gluonts
      joblib
      mlforecast
      networkx
      numpy
      pandas
      pytorch-lightning
      scipy
      statsforecast
      statsmodels
      torch
      tqdm
      ujson
    ];

    passthru.optional-dependencies = with prev; {
      tests = [
        black
        flake8
        flaky
        isort
        pytest
        pytest-timeout
      ];
    };

    pythonImportsCheck = [ "autogluon.timeseries" ];

    meta = {
      description = "AutoML for Image, Text, and Tabular Data";
      homepage = "https://pypi.org/project/autogluon-timeseries";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  autogluon = buildPythonPackage rec {
    pname = "autogluon";
    version = "0.8.2";
    format = "setuptools";

    src = fetchFromGitHub {
      owner = "autogluon";
      repo = "autogluon";
      rev = "refs/tags/v${version}";
      hash = "sha256-AjV/SY4wyAqGPba/SXtRDBXQ66gZZgVbQQG3GfAG8hk=";
    };

    preBuild = ''
      cd ./autogluon
      sed -i -E '/install_requires=/d' ./setup.py
    '';

    propagatedBuildInputs = with prev; [
      autogluon-core
      autogluon-features
      autogluon-multimodal
      autogluon-tabular
      autogluon-timeseries
    ];

    pythonImportsCheck = [ "autogluon" ];

    meta = {
      description = "AutoML for Image, Text, and Tabular Data";
      homepage = "https://pypi.org/project/autogluon/";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
