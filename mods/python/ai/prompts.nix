final: prev:
let
  inherit (prev) buildPythonPackage fetchPypi;
  inherit (prev.lib) licenses maintainers;
  inherit (prev.pkgs) fetchFromGitHub;
in
rec {
  guidance =
    let
      name = "guidance";
      version = "0.0.90";
    in
    buildPythonPackage rec {
      inherit version;
      pname = name;
      format = "setuptools";

      src = fetchFromGitHub {
        owner = "microsoft";
        repo = name;
        rev = "refs/tags/${version}";
        hash = "sha256-tQpDJprxctKI88F+CZ9aSJbVo7tjmI4+VrI+WO4QlxE=";
      };

      propagatedBuildInputs = with prev; [
        aiohttp
        diskcache
        gptcache
        msal
        nest-asyncio
        numpy
        openai
        platformdirs
        pygtrie
        pyparsing
        requests
        tiktoken
      ];

      nativeCheckInputs = with prev; [
        pytestCheckHook
        torch
        transformers
      ];

      passthru.optional-dependencies = with prev; {
        docs = [
          ipython
          nbsphinx
          numpydoc
          sphinx
          sphinx-rtd-theme
        ];
        test = [
          pytest
          pytest-cov
          torch
          transformers
        ];
      };

      disabledTestPaths = [
        "tests/library/test_each.py"
        "tests/library/test_gen.py"
        "tests/library/test_include.py"
        "tests/library/test_select.py"
        "tests/llms/caches/test_diskcache.py"
        "tests/llms/test_openai.py"
        "tests/llms/test_transformers.py"
        "tests/test_program.py"
      ];

      pythonImportsCheck = [ "guidance" ];

      meta = {
        description = "A guidance language for controlling large language models";
        homepage = "https://github.com/microsoft/guidance";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  nemoguardrails =
    let
      pname = "nemoguardrails";
      version = "0.4.0";
      format = "wheel";
      src = fetchPypi {
        inherit version;
        pname = "nemoguardrails";
        format = "wheel";
        python = "py3";
        dist = "py3";
        platform = "any";
        hash = "sha256-quTVk5uebggIT9qnude5PYHNwzA+XGq6AtSHdZyfD6A=";
      };
    in
    buildPythonPackage {
      inherit pname src version format;

      propagatedBuildInputs = with prev; [
        aiohttp
        annoy
        httpx
        langchain
        pydantic
        requests
        sentence-transformers
        simpleeval
        starlette
        transformers
        typer
        typing-extensions
        uvicorn
      ];

      pythonImportsCheck = [ "nemoguardrails" ];

      meta = {
        description = "open-source toolkit for easily adding programmable guardrails to LLM-based conversational systems";
        homepage = "https://github.com/NVIDIA/NeMo-Guardrails";
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  lmql = buildPythonPackage rec {
    pname = "lmql";
    version = "0.7.3";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-PAxGk0NYOIY9WKNlJP9wmVBotn7fLp2kqtiehkFphnU=";
    };

    nativeBuildInputs = with prev; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with prev; [
      aiohttp
      astunparse
      llama-cpp-python
      numpy
      openai
      termcolor
      tiktoken
    ];

    passthru.optional-dependencies = with prev; {
      hf = [
        accelerate
        transformers
      ];
      replicate = [
        aiohttp-sse-client
        transformers
      ];
      tests = [
        pytest
        pytest-asyncio
      ];
    };

    pythonImportsCheck = [ "lmql" ];

    meta = {
      description = "A query language for language models";
      homepage = "https://lmql.ai";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
