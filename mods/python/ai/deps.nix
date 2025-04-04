final: prev: with prev;
let
  inherit (pkgs) fetchFromGitHub;
in
rec {
  hnswlib = buildPythonPackage rec {
    pname = "hnswlib";
    version = "0.12.0";

    src = fetchFromGitHub {
      owner = "nmslib";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-XXz0NIQ5dCGwcX2HtbK5NFTalP0TjLO6ll6TmH3oflI=";
    };
    nativeBuildInputs = [
      pybind11
    ];
    propagatedBuildInputs = [
      numpy
      setuptools
    ];
    pythonImportsCheck = [
      "hnswlib"
    ];
    doCheck = false;
    meta = with lib; {
      description = "Header-only C++/python library for fast approximate nearest neighbors";
      homepage = "https://github.com/nmslib/hnswlib";
      changelog = "https://github.com/nmslib/hnswlib/releases/tag/v${version}";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  vellum-ai = buildPythonPackage rec {
    pname = "vellum-ai";
    version = "0.2.2";
    pyproject = true;

    src = fetchPypi {
      pname = "vellum_ai";
      inherit version;
      hash = "sha256-Dlap6p7LbU2MyvJj/2suoGOaKeynW7XFK4EJJ8GNNNY=";
    };

    nativeBuildInputs = [
      poetry-core
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = [
      "httpx"
      "pydantic"
    ];

    propagatedBuildInputs = [
      httpx
      pydantic
    ];

    pythonImportsCheck = [ "vellum" ];

    meta = with lib; {
      description = "";
      homepage = "https://www.vellum.ai/";
      license = with licenses; [ ];
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  strip-tags = buildPythonPackage rec {
    pname = "strip-tags";
    version = "0.3";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-SWTRs/+ueQTzmkAbFa/PGjzml3CIh/nG09TRJogPzoY=";
    };

    propagatedBuildInputs = [
      beautifulsoup4
      click
      html5lib
    ];

    passthru.optional-dependencies = {
      test = [
        pytest
      ];
    };

    pythonImportsCheck = [ "strip_tags" ];

    meta = with lib; {
      description = "Strip tags from HTML, optionally from areas identified by CSS selectors";
      homepage = "hhttps://github.com/simonw/strip-tags";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  ttok = buildPythonPackage rec {
    pname = "ttok";
    version = "0.1";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-i5Q59xviIuEXOSssizi7lOQWNBzLk4GRpWWJ7DNTlRo=";
    };

    propagatedBuildInputs = [
      click
      tiktoken
    ];

    passthru.optional-dependencies = {
      test = [
        cogapp
        pytest
      ];
    };

    pythonImportsCheck = [ "ttok" ];

    meta = with lib; {
      description = "Count and truncate text based on tokens";
      homepage = "https://github.com/simonw/ttok";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  analytics-python = buildPythonPackage rec {
    pname = "analytics-python";
    version = "1.4.0";

    disabled = pythonOlder "3.6";

    src = fetchPypi {
      inherit pname version;
      sha256 = "plFBq25H2zlvW8Vwix25P/mpmILYH+gIIor9Xrtt/l8=";
    };

    postPatch = ''
      substituteInPlace setup.py \
        --replace '"backoff==1.10.0"' '"backoff>=1.10.0,<3"'
    '';

    propagatedBuildInputs = [
      monotonic
      requests
      backoff
      python-dateutil
    ];

    # Almost all tests run against a hosted API, and the few that are mocked are hard to cherry-pick
    doCheck = false;

    pythonImportsCheck = [
      "analytics"
      "analytics.client"
      "analytics.consumer"
      "analytics.request"
      "analytics.utils"
      "analytics.version"
    ];

    meta = with lib; {
      homepage = "https://segment.com/libraries/python";
      description = "Hassle-free way to integrate analytics into any python application";
      license = licenses.mit;
      maintainers = with maintainers; [ pbsds ];
    };
  };

  ffmpy = buildPythonPackage rec {
    pname = "ffmpy";
    version = "0.3.0";

    disabled = pythonOlder "3.6";

    # The github repo has no release tags, the pypi distribution has no tests.
    # This package is quite trivial anyway, and the tests mainly play around with the ffmpeg cli interface.
    # https://github.com/Ch00k/ffmpy/issues/60
    src = fetchPypi {
      inherit pname version;
      sha256 = "dXWRWB7uJbSlCsn/ubWANaJ5RTPbR+BRL1P7LXtvmtw=";
    };

    propagatedBuildInputs = [
      pkgs.ffmpeg
    ];

    pythonImportsCheck = [ "ffmpy" ];

    meta = with lib; {
      description = "A simple python interface for FFmpeg/FFprobe";
      homepage = "https://github.com/Ch00k/ffmpy";
      license = licenses.mit;
      maintainers = with maintainers; [ pbsds ];
    };
  };

  flaskwebgui = buildPythonPackage {
    pname = "flaskwebgui";
    version = "1.0.6";
    format = "setuptools";

    src = fetchFromGitHub {
      owner = "ClimenteA";
      repo = "flaskwebgui";
      rev = "b77555b9a795dfd7154c5116f7dfde5ce238e99b";
      hash = "sha256-7+/WAwhY70nXFpK+2EnCkdGBBqTwq60HDcCpC35iSvE=";
    };

    propagatedBuildInputs = [
      psutil
    ];

    pythonImportsCheck = [ "flaskwebgui" ];

    meta = with lib; {
      description = "Create desktop applications with Flask/Django/FastAPI";
      homepage = "https://github.com/ClimenteA/flaskwebgui";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  simple-websocket = buildPythonPackage rec {
    pname = "simple-websocket";
    version = "0.10.0";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-gsCwsQBtVJDwn/ZjkjlNkN11goVjXtrSQeCT6air0+s=";
    };

    nativeBuildInputs = [
      setuptools
      wheel
    ];

    propagatedBuildInputs = [
      wsproto
    ];

    pythonImportsCheck = [ "simple_websocket" ];

    meta = with lib; {
      description = "Simple WebSocket server and client for Python";
      homepage = "https://github.com/miguelgrinberg/simple-websocket";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  controlnet-aux = buildPythonPackage rec {
    pname = "controlnet-aux";
    version = "0.0.7";
    format = "setuptools";

    src = fetchPypi {
      pname = "controlnet_aux";
      inherit version;
      hash = "sha256-23KZMjum04ni/mt9gTGgWica86SsKldHdUSMTQd4vow=";
    };

    propagatedBuildInputs = [
      einops
      filelock
      huggingface-hub
      importlib-metadata
      numpy
      opencv4
      pillow
      scikit-image
      scipy
      timm
      torch
      torchvision
    ];

    postPatch = ''
      sed -i -E \
        -e '/opencv-python/d' \
        ./setup.py
    '';

    pythonImportsCheck = [ "controlnet_aux" ];

    meta = with lib; {
      description = "Auxillary models for controlnet";
      homepage = "https://github.com/patrickvonplaten/controlnet_aux";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  pulsar-client =
    let
      pname = "pulsar-client";
      version = "3.2.0";
      format = "wheel";
      dists = {
        aarch64-darwin = {
          platform = "macosx_10_15_universal2";
          hash = "sha256-WE9EsDR0ppkGvnEaWXpNUWJjpVvjHkn8B75QPchAaCE=";
        };
        aarch64-linux = {
          platform = "manylinux_2_17_aarch64.manylinux2014_aarch64";
          hash = "sha256-pje5o7MIYMYeaKe46mUOCYfYnoL3O2o98atmKmQ4/do=";
        };
        x86_64-darwin = {
          platform = "macosx_10_15_universal2";
          hash = "sha256-WE9EsDR0ppkGvnEaWXpNUWJjpVvjHkn8B75QPchAaCE=";
        };
        x86_64-linux = {
          platform = "manylinux_2_17_x86_64.manylinux2014_x86_64";
          hash = "sha256-tKGH/cX+vPFvclF53PLEdvMe7r2DU3lNkXVKMgLdUHI=";
        };
      };
      d = dists.${final.stdenv.hostPlatform.system} or (throw "Unsupported system: ${final.stdenv.hostPlatform.system}");
      src = fetchPypi {
        inherit version format;
        inherit (d) hash platform;
        pname = "pulsar_client";
        abi = "cp311";
        python = "cp311";
        dist = "cp311";
      };
    in
    buildPythonPackage {
      inherit pname src version format;
      nativeBuildInputs = [ pkgs.autoPatchelfHook ];
      propagatedBuildInputs = [
        certifi
      ];
      pythonImportsCheck = [ "pulsar" ];

      meta = with lib; {
        description = "Apache Pulsar Python client library";
        homepage = "https://pulsar.apache.org";
        license = licenses.asl20;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  graphlib-backport = buildPythonPackage rec {
    pname = "graphlib-backport";
    version = "1.0.3";
    pyproject = true;

    src = fetchPypi {
      pname = "graphlib_backport";
      inherit version;
      hash = "sha256-e7j8d1e4rk5tgACibNSekjKqqaOqV+20eEdLhCS/quI=";
    };

    postPatch = ''
      sed -i -E 's#(poetry)>=1.0#\1-core#g' ./pyproject.toml
      substituteInPlace ./pyproject.toml --replace "poetry.masonry.api" "poetry.core.masonry.api"
    '';

    nativeBuildInputs = [
      poetry-core
    ];

    pythonImportsCheck = [ "graphlib" ];

    meta = with lib; {
      description = "Backport of the Python 3.9 graphlib module for Python 3.6";
      homepage = "https://github.com/mariushelf/graphlib_backport";
      license = with licenses; [ ];
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  sqlalchemy2-stubs = buildPythonPackage rec {
    pname = "sqlalchemy2-stubs";
    version = "0.0.2a32";

    disabled = pythonOlder "3.7";
    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-Kiz6tx01rGO/Ia2EHYYQzZOjvUxlYoSMU4+pdVhcJzk=";
    };

    propagatedBuildInputs = [ typing-extensions ];
    meta = with lib; { };
  };

  dalaipy = buildPythonPackage rec {
    pname = "dalaipy";
    version = "2.0.2";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-STGHZD73sNA6beogNP2de1tB8CCmK3Ty0rAOPFn5gjY=";
    };

    postPatch = ''
      mv src/ dalaipy/
    '';

    nativeBuildInputs = [
      setuptools
    ];

    propagatedBuildInputs = [
      python-socketio
    ];

    pythonImportsCheck = [ "dalaipy" ];

    meta = with lib; {
      description = "A Python Wrapper for Dalai";
      homepage = "https://github.com/wastella/dalaipy";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  clean-text = buildPythonPackage rec {
    pname = "clean-text";
    version = "0.6.0";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-g3SzhfwqJuBjg/Yq7Qdvpr4RXlgyI54qf9izRPqNKrI=";
    };

    postPatch = ''
      sed -i -E 's#(poetry)>=0.12#\1-core#g' ./pyproject.toml
      substituteInPlace ./pyproject.toml --replace "poetry.masonry.api" "poetry.core.masonry.api"
    '';

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      emoji_1
      ftfy
    ];

    passthru.optional-dependencies = {
      gpl = [
        unidecode
      ];
      sklearn = [
        pandas
        scikit-learn
      ];
    };

    pythonImportsCheck = [ "cleantext" ];

    meta = with lib; {
      description = "Functions to preprocess and normalize text";
      homepage = "https://pypi.org/project/clean-text/";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  textsum = buildPythonPackage rec {
    pname = "textsum";
    version = "0.2.0";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-WjoPyCAci9teBB2X2I0Ckz8ZPuVvV3a5bbxV4zcXfBQ=";
    };

    nativeBuildInputs = [
      setuptools
      setuptools-scm
    ];

    propagatedBuildInputs = [
      accelerate
      clean-text
      fire
      importlib-metadata
      natsort
      nltk
      torch
      tqdm
      transformers
    ];

    passthru.optional-dependencies = {
      all = [
        bitsandbytes
        gradio
        optimum
        pyspellchecker
        python-doctr
        rapidfuzz
      ];
      app = [
        gradio
        pyspellchecker
        python-doctr
        rapidfuzz
      ];
      optimum = [
        optimum
      ];
      pdf = [
        pyspellchecker
        python-doctr
      ];
      testing = [
        pytest
        pytest-cov
        setuptools
      ];
      unidecode = [
        unidecode
      ];
    };

    pythonImportsCheck = [ "textsum" ];

    meta = with lib; {
      description = "Utility for using transformers summarization models on text docs";
      homepage = "https://pypi.org/project/textsum/";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  nlpaug = buildPythonPackage rec {
    pname = "nlpaug";
    version = "0.0.15";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-ceFQgRkV0LHK64zXQCHSAWgmLOOMbHLZnZzTnWsWrm4=";
    };

    propagatedBuildInputs = [
      gdown
      numpy
      pandas
      requests
    ];

    nativeCheckInputs = [
      python-dotenv
      librosa
      torch
      transformers
    ];

    doCheck = false;

    pythonImportsCheck = [ "nlpaug" ];

    meta = with lib; {
      description = "Natural language processing augmentation library for deep neural networks";
      homepage = "https://pypi.org/project/nlpaug/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  gluonts = buildPythonPackage rec {
    pname = "gluonts";
    version = "0.13.4";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-50+tRpzajpTZYL0KGj+hoxPZZajQiGwsTGglEIb/AuA=";
    };

    nativeBuildInputs = [
      setuptools
    ];

    propagatedBuildInputs = [
      numpy
      pandas
      pydantic
      toolz
      tqdm
      typing-extensions
    ];

    pythonImportsCheck = [ "gluonts" ];

    meta = with lib; {
      description = "Probabilistic time series modeling in Python";
      homepage = "https://pypi.org/project/gluonts/";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  triad = buildPythonPackage rec {
    pname = "triad";
    version = "0.9.1";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-r8P9nyJSR5dP0RcPl0SNgRHvAR0tjLF6NQPD/Hlc9ZQ=";
    };

    propagatedBuildInputs = [
      fs
      fsspec
      importlib-metadata
      numpy
      pandas
      pyarrow
      six
    ];

    passthru.optional-dependencies = {
      ciso8601 = [
        ciso8601
      ];
    };

    pythonImportsCheck = [ "triad" ];

    meta = with lib; {
      description = "A collection of python utils for Fugue projects";
      homepage = "https://pypi.org/project/triad/";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  adagio = buildPythonPackage rec {
    pname = "adagio";
    version = "0.2.4";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-5Yq8RTkYSmX6+ZVpV9N4dha+3rEwOsXJsaIB2K9rh9c=";
    };

    propagatedBuildInputs = [
      triad
    ];

    pythonImportsCheck = [ "adagio" ];

    doCheck = false;

    meta = with lib; {
      description = "The Dag IO Framework for Fugue projects";
      homepage = "https://pypi.org/project/adagio/";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  fugue-sql-antlr = buildPythonPackage rec {
    pname = "fugue-sql-antlr";
    version = "0.1.6";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-d4e7Do+p4TM80Jpv7pE8rh4C7Cb5HKuunoIa30zKT14=";
    };

    preBuild = ''
      sed -i -E \
        -e '/jinja2/d' \
        -e '/antlr4-python3-runtime/d' \
        -e '/triad>=/d' \
        ./setup.py
    '';

    propagatedBuildInputs = [
      antlr4-python3-runtime
    ];

    pythonImportsCheck = [ "fugue_sql_antlr" ];

    meta = with lib; {
      description = "Fugue SQL Antlr Parser";
      homepage = "https://pypi.org/project/fugue-sql-antlr/";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  fugue = buildPythonPackage rec {
    pname = "fugue";
    version = "0.8.6";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-TjDE7bruMadouaCX5g0ps51zagMC07YRB13j+nMWLQk=";
    };

    propagatedBuildInputs = [
      adagio
      fugue-sql-antlr
      jinja2
      pandas
      pyarrow
      qpd
      sqlglot
      triad
    ];

    pythonImportsCheck = [ "fugue" ];

    doCheck = false;

    meta = with lib; {
      description = "An abstraction layer for distributed computation";
      homepage = "https://pypi.org/project/fugue/";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  qpd = buildPythonPackage rec {
    pname = "qpd";
    version = "0.4.4";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-4O0FuI4yHqmTWHQ3e9oRM5yQ8UafNDROm0HRa4CI4TY=";
    };

    preBuild = ''
      sed -i -E \
        -e '/antlr4-python3-runtime/d' \
        ./setup.py
    '';

    doCheck = false;

    propagatedBuildInputs = [
      adagio
      antlr4-python3-runtime
      pandas
      triad
    ];

    passthru.optional-dependencies = {
      all = [
        cloudpickle
        dask
      ];
      dask = [
        cloudpickle
        dask
      ];
    };

    pythonImportsCheck = [ "qpd" ];

    meta = with lib; {
      description = "Query Pandas Using SQL";
      homepage = "https://pypi.org/project/qpd/";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  statsforecast = buildPythonPackage rec {
    pname = "statsforecast";
    version = "1.6.0";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-23PsIbyB8k1eItNQiwoghKRRFxmyQKkigj2yg9uhLFI=";
    };

    propagatedBuildInputs = [
      fugue
      matplotlib
      numba
      numpy
      pandas
      polars
      prophet
      scipy
      statsmodels
      tqdm
    ];

    nativeCheckInputs = [
      pytestCheckHook
      ray
      dask
      pyspark
    ];

    pythonImportsCheck = [ "statsforecast" ];

    disabledTests = [
      "test_dask_flow"
      "test_dask_flow_with_level"
      "test_ray_flow"
      "test_ray_flow_with_level"
      "test_spark_flow"
      "test_spark_flow_with_level"
    ];

    meta = with lib; {
      description = "Time series forecasting suite using statistical models";
      homepage = "https://pypi.org/project/statsforecast/";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  window-ops = buildPythonPackage rec {
    pname = "window-ops";
    version = "0.0.14";
    format = "setuptools";

    src = fetchPypi {
      pname = "window_ops";
      inherit version;
      hash = "sha256-TA1GhsULofwd59Qdpwa1cRjY+0VTHloj8GEE+AR4jB0=";
    };

    propagatedBuildInputs = [
      numba
      numpy
    ];

    passthru.optional-dependencies = {
      dev = [
        pandas
      ];
    };

    pythonImportsCheck = [ "window_ops" ];

    meta = with lib; {
      description = "Implementations of window operations such as rolling and expanding";
      homepage = "https://pypi.org/project/window-ops/";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  mlforecast = buildPythonPackage rec {
    pname = "mlforecast";
    version = "0.9.2";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-ZUW8jn9rg/F4JE8d2Xc/oEJxebEY7+aYD/7gxQl9y5s=";
    };

    nativeBuildInputs = [
      setuptools
    ];

    propagatedBuildInputs = [
      numba
      pandas
      scikit-learn
      window-ops
    ];

    pythonImportsCheck = [ "mlforecast" ];

    meta = with lib; {
      description = "Scalable machine learning based time series forecasting";
      homepage = "https://pypi.org/project/mlforecast/";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  dirtyjson = buildPythonPackage rec {
    pname = "dirtyjson";
    version = "1.0.8";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-kMpKGPP/MM6EnRANz0oAOVPHnTojSO8Fbx2cIiMaJf0=";
    };

    nativeBuildInputs = with final; [
      setuptools
      wheel
    ];

    pythonImportsCheck = [ "dirtyjson" ];

    meta = with lib; {
      description = "JSON decoder for Python that can extract data from the muck";
      homepage = "https://pypi.org/project/dirtyjson/";
      license = licenses.afl21;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  mistralai = buildPythonPackage rec {
    pname = "mistralai";
    version = "0.0.12";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-/mUoNhRqFb3OdpGpWAOjLFPGQcVAAJNEf/qTvy7SlrI=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      httpx
      orjson
      pydantic
    ];

    pythonImportsCheck = [ "mistralai" ];

    meta = with lib; {
      description = "";
      homepage = "https://pypi.org/project/mistralai/";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  typer-config = buildPythonPackage rec {
    pname = "typer-config";
    version = "1.4.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "maxb2";
      repo = "typer-config";
      rev = version;
      hash = "sha256-58dlMpEGRyWqtUIPsq0xVFTJVbOkV8CmI+yRFIi+N2c=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      typer
    ];

    pythonImportsCheck = [ "typer_config" ];

    meta = with lib; {
      description = "Utilities for working with configuration files in typer CLIs";
      homepage = "https://github.com/maxb2/typer-config";
      changelog = "https://github.com/maxb2/typer-config/blob/${src.rev}/CHANGELOG.md";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  autotiktokenizer = buildPythonPackage rec {
    pname = "autotiktokenizer";
    version = "0.1.2";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "bhavnicksm";
      repo = "autotiktokenizer";
      rev = "v${version}";
      hash = "sha256-d3YsVl70yVdBWprT0YA+1bW09zd0gQwg7nVMp92JzNU=";
    };

    build-system = [
      setuptools
      wheel
    ];

    dependencies = [
      tiktoken
      tokenizers
    ];

    optional-dependencies = {
      dev = [
        pytest
      ];
    };

    pythonImportsCheck = [
      "autotiktokenizer"
    ];

    meta = {
      description = "The AutoTokenizer that TikToken always needed -- Load any tokenizer with TikToken now";
      homepage = "https://github.com/bhavnicksm/autotiktokenizer";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [ jpetrucciani ];
    };
  };

  chonkie = buildPythonPackage rec {
    pname = "chonkie";
    version = "0.1.2";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "bhavnicksm";
      repo = "chonkie";
      rev = "v${version}";
      hash = "sha256-diHT5RVo9WlRHBeVdYwMtbk3u6C6V4gWOkWwWiZ2+ro=";
    };

    build-system = [
      setuptools
      wheel
    ];

    dependencies = [
      autotiktokenizer
      tiktoken
      tokenizers
    ];

    optional-dependencies = {
      all = [
        numpy
        sentence-transformers
        spacy
      ];
      dev = [
        black
        flake8
        isort
        mypy
        pre-commit
        pylint
        pytest
        tiktoken
        transformers
      ];
      semantic = [
        numpy
        sentence-transformers
      ];
      sentence = [
        spacy
      ];
    };

    pythonImportsCheck = [
      "chonkie"
    ];

    meta = {
      description = "CHONK your texts with Chonkie ✨ - The no-nonsense RAG chunking library";
      homepage = "https://github.com/bhavnicksm/chonkie";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [ jpetrucciani ];
    };
  };

  graphiti = buildPythonPackage rec {
    pname = "graphiti";
    version = "0.4.2";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "getzep";
      repo = "graphiti";
      rev = "v${version}";
      hash = "sha256-yETE+Nww3KaBPpOgrm/g4JjbNCFIb5afvaATz1n3n+s=";
    };

    build-system = [
      poetry-core
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = [ "openai" ];

    dependencies = [
      diskcache
      neo4j
      numpy
      openai
      pydantic
      python-dotenv
      tenacity
    ];

    pythonImportsCheck = [
      "graphiti_core"
    ];

    meta = {
      description = "Build and query dynamic, temporally-aware Knowledge Graphs";
      homepage = "https://github.com/getzep/graphiti";
      license = lib.licenses.asl20;
      maintainers = with lib.maintainers; [ jpetrucciani ];
    };
  };

  graphiti-server = buildPythonPackage rec {
    pname = "graphiti-server";
    version = "0.4.2";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "getzep";
      repo = "graphiti";
      rev = "v${version}";
      hash = "sha256-yETE+Nww3KaBPpOgrm/g4JjbNCFIb5afvaATz1n3n+s=";
    };
    sourceRoot = "source/server";

    build-system = [
      poetry-core
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = [
      "fastapi"
      "uvicorn"
    ];

    dependencies = [
      fastapi
      graphiti
      pydantic-settings
      uvicorn
    ];

    pythonImportsCheck = [
      "graph_service"
    ];

    meta = {
      description = "Build and query dynamic, temporally-aware Knowledge Graphs";
      homepage = "https://github.com/getzep/graphiti";
      license = lib.licenses.asl20;
      maintainers = with lib.maintainers; [ jpetrucciani ];
    };
  };

  smolagents = buildPythonPackage rec {
    pname = "smolagents";
    version = "1.6.0";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-FcG0e66RyPYnfkU1+7wXNoR62XAlTa7Yw0O5iCxZx18=";
    };

    build-system = [
      pythonRelaxDepsHook
      setuptools
    ];

    pythonRelaxDeps = [ "duckduckgo-search" ];

    dependencies = [
      duckduckgo-search
      huggingface-hub
      jinja2
      markdownify
      pandas
      pillow
      requests
      rich
    ];

    optional-dependencies = {
      all = [
        smolagents
      ];
      audio = [
        smolagents
        soundfile
      ];
      dev = [
        smolagents
        sqlalchemy
      ];
      e2b = [
        e2b-code-interpreter
        python-dotenv
      ];
      gradio = [
        gradio
      ];
      litellm = [
        litellm
      ];
      mcp = [
        mcp
        mcpadapt
      ];
      openai = [
        openai
      ];
      quality = [
        ruff
      ];
      test = [
        ipython
        pytest
        python-dotenv
        rank-bm25
        smolagents
      ];
      torch = [
        torch
        torchvision
      ];
      transformers = [
        accelerate
        smolagents
        transformers
      ];
    };

    pythonImportsCheck = [
      "smolagents"
    ];

    meta = {
      description = "Smolagents: a barebones library for agents. Agents write python code to call tools or orchestrate other agents";
      homepage = "https://pypi.org/project/smolagents/";
      license = lib.licenses.asl20;
      maintainers = with lib.maintainers; [ jpetrucciani ];
    };
  };
}
