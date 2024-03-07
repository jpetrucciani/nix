final: prev:
let
  inherit (prev) buildPythonPackage fetchPypi;
  inherit (prev.lib) licenses maintainers;
  inherit (prev.pkgs) fetchFromGitHub;
in
{
  lama-cleaner =
    let
      name = "lama-cleaner";
      version = "1.2.1";
    in
    buildPythonPackage {
      inherit version;
      pname = name;
      format = "setuptools";

      src = fetchFromGitHub {
        owner = "Sanster";
        repo = name;
        rev = "203e775e2ed9bda2c55b15bba71a2a107ba7b8d2";
        hash = "sha256-r0ZiHdUdEckqR2TmsJDrH5/4Jp63IZRMNex1iqqDHHQ=";
      };

      propagatedBuildInputs = with prev; [
        accelerate
        # controlnet-aux
        diffusers
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
        yacs
      ];

      postPatch = ''
        sed -i -E \
          -e '/opencv-python/d' \
          -e '/diffusers\[torch/d' \
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

      pythonImportsCheck = [ "lama_cleaner" ];
      doCheck = false;

      meta = {
        description = "Image inpainting tool powered by SOTA AI Model";
        homepage = "https://github.com/Sanster/lama-cleaner";
        mainProgram = "lama-cleaner";
        license = licenses.asl20;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

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
