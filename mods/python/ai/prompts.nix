final: prev:
let
  inherit (prev) buildPythonPackage fetchPypi;
  inherit (prev.lib) licenses maintainers;
  inherit (prev.pkgs) fetchFromGitHub;
in
{
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
