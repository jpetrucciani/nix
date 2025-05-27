final: prev:
let
  inherit (prev) buildPythonPackage fetchPypi;
  inherit (prev.lib) licenses maintainers;
  inherit (prev.pkgs) fetchFromGitHub;

  # wip for now
  _iopaint-base =
    let
      name = "iopaint";
      version = "1.2.2";
    in
    buildPythonPackage {
      inherit version;
      pname = name;
      format = "setuptools";

      src = fetchFromGitHub {
        owner = "Sanster";
        repo = name;
        rev = "refs/tags/iopaint-${version}";
        hash = "sha256-jY2NZVhcFH+YXcbasTXEyhswOKaLx3lqAzYQlyYhAgk=";
      };

      propagatedBuildInputs = with prev; [
        accelerate
        controlnet-aux
        diffusers
        einops
        flask
        flask-cors
        flask-socketio
        flaskwebgui
        gradio
        jinja2
        loguru
        markupsafe
        omegaconf
        opencv4
        peft
        piexif
        pydantic
        pytest
        rich
        safetensors
        scikit-image
        simple-websocket
        torch
        torchvision
        tqdm
        transformers
        typer
        typer-config
        yacs
      ];

      postPatch = ''
        sed -i -E \
          -e '/controlnet-aux/d' \
          ./requirements.txt
      '';

      pythonRelaxDeps = [
        "Jinja2"
        "flask"
        "flaskwebgui"
        "markupsafe"
        "transformers"
      ];

      nativeBuildInputs = with prev; [
        pythonRelaxDepsHook
      ];

      pythonImportsCheck = [ "iopaint" ];
      doCheck = false;

      meta = {
        description = "Image inpainting tool powered by SOTA AI Models";
        homepage = "https://github.com/Sanster/iopaint";
        mainProgram = "iopaint";
        license = licenses.asl20;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  _io-paint = buildPythonPackage rec {
    pname = "io-paint";
    version = "1.2.2";
    pyproject = true;

    src = fetchPypi {
      pname = "IOPaint";
      inherit version;
      hash = "sha256-653nYW5qbfW/taf/W6vB12fl0YaEoieRWjE/kIuN/t4=";
    };
    postPatch = "touch ./requirements.txt";

    nativeBuildInputs = with final; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with final; [
      accelerate
      # controlnet-aux
      diffusers
      easydict
      einops
      fastapi
      gradio
      loguru
      omegaconf
      opencv4
      peft
      piexif
      pillow
      pydantic
      python-multipart
      python-socketio
      rich
      safetensors
      torch
      torchvision
      transformers
      typer
      typer-config
      uvicorn
      yacs
    ];

    pythonImportsCheck = [ "iopaint" ];

    meta = {
      description = "Image inpainting, outpainting tool powered by SOTA AI Model";
      homepage = "https://github.com/Sanster/iopaint";
      license = licenses.asl20;
      mainProgram = "iopaint";
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

in
{
  io-paint = _io-paint;
  io-paint-cuda = _io-paint.override { torch = final.torchWithCuda; };
  chainforge = buildPythonPackage rec {
    pname = "chainforge";
    version = "0.2.5.3";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-zOSflYxezkqhGDXrw3ttbNqx3zU0rUYNWGLzSJizurc=";
    };

    postPatch = ''
      sed -i -E '/urllib3/d' ./setup.py
    '';

    propagatedBuildInputs = with prev; [
      (anthropic.overridePythonAttrs (_: { doCheck = false; }))
      asgiref
      dalaipy
      flask
      flask-cors
      google-generativeai
      mistune
      openai
      requests
      urllib3
    ];

    pythonRelaxDeps = [
      "urllib3"
    ];

    nativeBuildInputs = with prev; [
      pythonRelaxDepsHook
    ];

    pythonImportsCheck = [ "chainforge" ];

    meta = {
      description = "A Visual Programming Environment for Prompt Engineering";
      homepage = "https://github.com/ianarawjo/ChainForge";
      license = licenses.mit;
      mainProgram = "chainforge";
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  bark = buildPythonPackage rec {
    pname = "bark";
    version = "unstable-2023-08-31";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "suno-ai";
      repo = pname;
      rev = "cb89688307c28cbd2d8bbfc78e534b9812673a26";
      hash = "sha256-hpM+m4cMymFsy8GJQQ29LoLoZx3i6PxIfASU49VSuk8=";
    };

    nativeBuildInputs = with prev; [
      setuptools
    ];

    propagatedBuildInputs = with prev; [
      boto3
      encodec
      funcy
      huggingface-hub
      numpy
      scipy
      tokenizers
      torch-bin
      tqdm
      transformers
    ];

    passthru.optional-dependencies = with prev; {
      dev = [
        bandit
        black
        codecov
        flake8
        hypothesis
        isort
        jupyter
        mypy
        nbconvert
        nbformat
        pydocstyle
        pylint
        pytest
        pytest-cov
      ];
    };

    pythonImportsCheck = [ "bark" ];

    meta = {
      description = "Text-Prompted Generative Audio Model";
      homepage = "https://github.com/suno-ai/bark";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  poppler-utils = buildPythonPackage rec {
    pname = "poppler-utils";
    version = "0.1.0";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-6XqS3P3leyGpDDBwaU5Y+O6hVVFa6OYkJmoFLQd2o0k=";
    };

    nativeBuildInputs = with final; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with final; [
      click
    ];

    passthru.optional-dependencies = with final; {
      dev = [
        click
        sphinx
      ];
    };

    pythonImportsCheck = [ "poppler" ];

    meta = {
      description = "Precompiled command-line utilities (based on Poppler) for manipulating PDF files and converting them to other formats";
      homepage = "https://pypi.org/project/poppler-utils/";
      license = licenses.gpl2Only;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  flupy = buildPythonPackage rec {
    pname = "flupy";
    version = "1.2.0";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-Ekh6AI6XRM010PbqPPoG9LKyfLE4v1fQeI9cJuV6/mk=";
    };

    nativeBuildInputs = with final; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with final; [
      typing-extensions
    ];

    pythonImportsCheck = [ "flupy" ];

    meta = {
      description = "Method chaining built on generators";
      homepage = "https://pypi.org/project/flupy/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  vecs = buildPythonPackage rec {
    pname = "vecs";
    version = "0.4.4";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-PgNJHAWkdISjOzLW7B2fSEERa6cwftmZRRBnjwmDFv0=";
    };

    nativeBuildInputs = with final; [
      setuptools
      wheel
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = [
      "pgvector"
    ];

    propagatedBuildInputs = with final; [
      deprecated
      flupy
      pgvector
      psycopg2
      sqlalchemy
    ];

    preBuild = ''
      substituteInPlace ./setup.py --replace 'psycopg2-binary' 'psycopg2'
    '';


    pythonImportsCheck = [ "vecs" ];

    meta = {
      description = "Pgvector client";
      homepage = "https://pypi.org/project/vecs/";
      license = with licenses; [ asl20 mit ];
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  r2r = buildPythonPackage rec {
    pname = "r2r";
    version = "0.2.85";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-xXEWi/lUlKuhfacGL01Tin34sy68DWpccGZflzeCf4U=";
    };

    nativeBuildInputs = with final; [
      poetry-core
      setuptools
      wheel
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = [
      "alembic"
      "fastapi"
      "fire"
      "fsspec"
      "gunicorn"
      "ollama"
      "posthog"
      "pydantic"
      "uvicorn"
    ];

    propagatedBuildInputs = with final; [
      aiosqlite
      alembic
      asyncpg
      bcrypt
      beautifulsoup4
      email-validator
      fastapi
      fire
      fsspec
      gunicorn
      litellm
      markdown
      neo4j
      nest-asyncio
      ollama
      openai
      openpyxl
      passlib
      poppler-utils
      posthog
      psutil
      pydantic
      pyjwt
      pypdf
      python-docx
      python-multipart
      python-pptx
      pyyaml
      redis
      requests
      sqlalchemy
      toml
      types-requests
      uvicorn
      vecs
    ];

    passthru.optional-dependencies = with final; {
      all = [
        moviepy
        opencv-python
      ];
      ingest-movies = [
        moviepy
        opencv-python
      ];
    };

    pythonImportsCheck = [ "r2r" ];

    meta = {
      description = "SciPhi R2R";
      homepage = "https://pypi.org/project/r2r/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  # fix issue with transformers?
  # https://github.com/huggingface/optimum/issues/2277
  optimum = prev.optimum.overridePythonAttrs (_: {
    postInstall = ''
      sed -i -E 's#(if is\_transformers\_version\(">=", ")4.49#\16.0#g' $out/lib/python*/site-packages/optimum/bettertransformer/__init__.py
    '';
  });

  infinity-emb = buildPythonPackage rec {
    pname = "infinity-emb";
    version = "0.0.76";
    pyproject = true;

    src = fetchPypi {
      pname = "infinity_emb";
      inherit version;
      hash = "sha256-/lq8bEPPH8GN8l/ca3dhv6QCAiXLNXh/Pcgy2rHg8ew=";
    };

    build-system = with final; [
      poetry-core
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = [
      "numpy"
    ];

    dependencies = with final; [
      ctranslate2
      diskcache
      einops
      fastapi
      hf-transfer
      httptools
      huggingface-hub
      numpy
      optimum
      orjson
      pillow
      prometheus-fastapi-instrumentator
      pydantic
      rich
      sentence-transformers
      timm
      torch
      typer
      uvicorn
      xformers
    ];

    optional-dependencies = with final; {
      onnxruntime-gpu = [
        onnxruntime-gpu
      ];
      optimum = [
        optimum
      ];
      tensorrt = [
        tensorrt
      ];
      torch = [
        sentence-transformers
        torch
      ];
      vision = [
        pillow
        timm
      ];
    };

    pythonImportsCheck = [
      "infinity_emb"
    ];

    meta = {
      description = "Infinity is a high-throughput, low-latency REST API for serving text-embeddings, reranking models and clip";
      homepage = "https://pypi.org/project/infinity-emb/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
      mainProgram = "infinity_emb";
    };
  };
}
