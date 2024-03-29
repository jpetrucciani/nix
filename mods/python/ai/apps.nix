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
}
