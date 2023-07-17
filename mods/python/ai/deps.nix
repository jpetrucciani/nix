final: prev: with prev; rec {
  sse-starlette = buildPythonPackage rec {
    pname = "sse-starlette";
    version = "1.6.1";
    format = "pyproject";

    src = pkgs.fetchFromGitHub {
      owner = "sysid";
      repo = pname;
      rev = "refs/tags/v${version}";
      hash = "sha256-b96J+P0X/4oxEZf6X58lUhExF2DapDn1EdxXIUbqrhs=";
    };

    nativeBuildInputs = [
      setuptools
      wheel
    ];

    propagatedBuildInputs = [
      starlette
    ];

    pythonImportsCheck = [ "sse_starlette" ];

    meta = with lib; {
      description = "SSE plugin for Starlette";
      homepage = "https://github.com/sysid/sse-starlette";
      license = licenses.bsd3;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  hnswlib = buildPythonPackage rec {
    pname = "hnswlib";
    version = "0.7.0";

    src = pkgs.fetchFromGitHub {
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

  clickhouse-connect = buildPythonPackage rec {
    pname = "clickhouse-connect";
    version = "0.5.24";
    format = "setuptools";

    src = pkgs.fetchFromGitHub {
      owner = "ClickHouse";
      repo = pname;
      rev = "refs/tags/v${version}";
      hash = "sha256-Ff4E7zAPZt5vK/pOvw1S7doEOSgADrrUrjEUpk7cvgQ=";
    };

    nativeBuildInputs = [
      cython
      setuptools
    ];

    nativeCheckInputs = [
      pytestCheckHook
      pytest-mock
      sqlalchemy
    ];

    propagatedBuildInputs = [
      certifi
      clickhouse-driver
      lz4
      numpy
      pandas
      pytz
      urllib3
      zstandard
    ];

    preBuild = ''
      cythonize --inplace clickhouse_connect/driverc/{buffer,dataconv,npconv}.pyx
    '';

    passthru.optional-dependencies = {
      arrow = [
        pyarrow
      ];
      numpy = [
        numpy
      ];
      orjson = [
        orjson
      ];
      pandas = [
        pandas
      ];
      sqlalchemy = [
        sqlalchemy
      ];
      superset = [
        apache-superset
      ];
    };

    disabledTestPaths = [
      "examples/perf_test.py"
      "tests/integration_tests/*"
    ];

    pythonImportsCheck = [ "clickhouse_connect" ];

    meta = with lib; {
      description = "ClickHouse core driver, SqlAlchemy, and Superset libraries";
      homepage = "https://github.com/ClickHouse/clickhouse-connect";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  posthog = buildPythonPackage rec {
    pname = "posthog";
    version = "2.5.0";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-dgHvdbSD62emIpyv7ALaliT21G32EGZ3HKnj+YYoT8M=";
    };

    propagatedBuildInputs = [
      backoff
      monotonic
      python-dateutil
      requests
      setuptools
      six
    ];

    passthru.optional-dependencies = {
      dev = [
        black
        flake8
        flake8-print
        isort
        pre-commit
      ];
      sentry = [
        django
        sentry-sdk
      ];
      test = [
        coverage
        flake8
        freezegun
        mock
        pylint
        pytest
      ];
    };

    pythonImportsCheck = [ "posthog" ];

    meta = with lib; {
      description = "Integrate PostHog into any python application";
      homepage = "https://github.com/posthog/posthog-python";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  vellum-ai = buildPythonPackage rec {
    pname = "vellum-ai";
    version = "0.0.15";
    format = "pyproject";

    src = fetchPypi {
      pname = "vellum_ai";
      inherit version;
      hash = "sha256-bZIUe1z05tlmCFOOmXc6MZuZhQR+duXzfH+6YXdrzog=";
    };

    nativeBuildInputs = [
      poetry-core
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

  diffusers = buildPythonPackage rec {
    pname = "diffusers";
    version = "0.16.1";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-TNdAA4LIbYXghCVVDeGxqB1O0DYj+9S82Dd4ZNnEbv4=";
    };

    propagatedBuildInputs = [
      filelock
      huggingface-hub
      importlib-metadata
      numpy
      pillow
      regex
      requests
      setuptools
    ];

    passthru.optional-dependencies = {
      dev = [
        accelerate
        black
        compel
        datasets
        flax
        hf-doc-builder
        isort
        jax
        jaxlib
        jinja2
        k-diffusion
        librosa
        note-seq
        parameterized
        protobuf
        pytest
        pytest-timeout
        pytest-xdist
        requests-mock
        ruff
        safetensors
        scipy
        sentencepiece
        tensorboard
        torch
        torchvision
        transformers
      ];
      docs = [
        hf-doc-builder
      ];
      flax = [
        flax
        jax
        jaxlib
      ];
      quality = [
        black
        hf-doc-builder
        isort
        ruff
      ];
      test = [
        compel
        datasets
        jinja2
        k-diffusion
        librosa
        note-seq
        parameterized
        pytest
        pytest-timeout
        pytest-xdist
        requests-mock
        safetensors
        scipy
        sentencepiece
        torchvision
        transformers
      ];
      torch = [
        accelerate
        torch
      ];
      training = [
        accelerate
        datasets
        jinja2
        protobuf
        tensorboard
      ];
    };

    pythonImportsCheck = [ "diffusers" ];

    meta = with lib; {
      description = "State-of-the-art diffusion models for image and audio generation in PyTorch";
      homepage = "https://github.com/huggingface/diffusers";
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

  gradio-client = buildPythonPackage rec {
    pname = "gradio-client";
    version = "0.2.10";
    format = "pyproject";

    src = fetchPypi {
      pname = "gradio_client";
      inherit version;
      hash = "sha256-1Pk8hmSfdmLsFoYVBq6GTRhmdCLoyOzCJzYPKu3P/ck=";
    };

    nativeBuildInputs = [
      hatch-fancy-pypi-readme
      hatch-requirements-txt
      hatchling
    ];

    propagatedBuildInputs = [
      fsspec
      httpx
      huggingface-hub
      packaging
      requests
      typing-extensions
      websockets
    ];

    pythonImportsCheck = [ "gradio_client" ];

    meta = with lib; {
      description = "Python library for easily interacting with trained machine learning models";
      homepage = "https://github.com/gradio-app/gradio";
      license = licenses.asl20;
      maintainers = with maintainers; [ ];
    };
  };

  gradio = buildPythonPackage rec {
    pname = "gradio";
    version = "3.35.2";
    disabled = pythonOlder "3.7";
    format = "pyproject";

    # We use the Pypi release, as it provides prebuild webui assets,
    # and its releases are also more frequent than github tags
    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-crr+bgJ44o3wp85ym15K2M2y4H88rIU7CnNGPzjWO7s=";
    };

    nativeBuildInputs = [
      hatchling
      hatch-requirements-txt
      hatch-fancy-pypi-readme
    ];
    propagatedBuildInputs = [
      altair
      aiohttp
      aiofiles
      analytics-python
      fastapi
      ffmpy
      gradio-client
      matplotlib
      numpy
      orjson
      pandas
      paramiko
      pillow
      pycryptodome
      python-multipart
      pydub
      requests
      uvicorn
      jinja2
      fsspec
      httpx
      pydantic
      semantic-version
      websockets
      markdown-it-py
      mdit-py-plugins
      linkify-it-py
    ];

    postPatch = ''
      # Unpin h11, as its version was only pinned to aid dependency resolution.
      # Basically a revert of https://github.com/gradio-app/gradio/pull/1680
      substituteInPlace requirements.txt \
        --replace "h11<0.13,>=0.11" "" \
        --replace "mdit-py-plugins<=0.3.3" "mdit-py-plugins>=0.3.3"
    '';

    doCheck = false;

    meta = with lib; {
      homepage = "https://www.gradio.app/";
      description = "Python library for easily interacting with trained machine learning models";
    };
  };

  flaskwebgui = buildPythonPackage {
    pname = "flaskwebgui";
    version = "1.0.6";
    format = "setuptools";

    src = pkgs.fetchFromGitHub {
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
    format = "pyproject";

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
    version = "0.0.5";
    format = "setuptools";

    src = fetchPypi {
      pname = "controlnet_aux";
      inherit version;
      hash = "sha256-xtwtVN/afiTblqocThBq7cVj3BQqNHtfOOzS8TuxBOk=";
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
      d = dists.${prev.stdenv.hostPlatform.system} or (throw "Unsupported system: ${prev.stdenv.hostPlatform.system}");
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
    format = "pyproject";

    src = fetchPypi {
      pname = "graphlib_backport";
      inherit version;
      hash = "sha256-e7j8d1e4rk5tgACibNSekjKqqaOqV+20eEdLhCS/quI=";
    };

    postPatch = ''
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
}
