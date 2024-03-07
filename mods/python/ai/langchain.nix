final: prev:
let
  inherit (prev) buildPythonPackage fetchPypi;
  inherit (prev.lib) licenses maintainers;
  inherit (prev.pkgs) fetchFromGitHub;
in
rec {
  langsmith = buildPythonPackage rec {
    pname = "langsmith";
    version = "0.1.20";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-2AuPn/YkkPJIZkbf2LpIlBbFCPaVHsIBH7WPceDjxoI=";
    };

    nativeBuildInputs = with prev; [
      poetry-core
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = [
      "orjson"
    ];

    propagatedBuildInputs = with prev; [
      orjson
      pydantic
      requests
    ];

    pythonImportsCheck = [ "langsmith" ];

    meta = {
      description = "Client library to connect to the LangChainPlus LLM Tracing and Evaluation Platform";
      homepage = "https://www.langchain.plus";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  langchain-text-splitters = buildPythonPackage rec {
    pname = "langchain-text-splitters";
    version = "0.0.1";
    pyproject = true;

    src = fetchPypi {
      pname = "langchain_text_splitters";
      inherit version;
      hash = "sha256-rEWfqYeZ9RF61UJakzCyGWEyHjC8GaKi+fdh3a3WKqE=";
    };

    nativeBuildInputs = with final; [
      poetry-core
    ];

    propagatedBuildInputs = [
      langchain-core
    ];

    pythonImportsCheck = [ "langchain_text_splitters" ];

    meta = {
      description = "LangChain text splitting utilities";
      homepage = "https://pypi.org/project/langchain-text-splitters/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  langchain-community = buildPythonPackage rec {
    pname = "langchain-community";
    version = "0.0.25";
    pyproject = true;

    src = fetchPypi {
      pname = "langchain_community";
      inherit version;
      hash = "sha256-tsjBTNbsJjXlHjl0v3io3juVm77bSvVarRZPjPOS8MU=";
    };

    nativeBuildInputs = with final; [
      poetry-core
    ];

    propagatedBuildInputs = with final; [
      aiohttp
      dataclasses-json
      langchain-core
      langsmith
      numpy
      pyyaml
      requests
      sqlalchemy
      tenacity
    ];

    pythonImportsCheck = [ "langchain_community" ];

    meta = {
      description = "Community contributed LangChain integrations";
      homepage = "https://pypi.org/project/langchain-community/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  langchain-core = buildPythonPackage rec {
    pname = "langchain-core";
    version = "0.1.29";
    pyproject = true;

    src = fetchPypi {
      pname = "langchain_core";
      inherit version;
      hash = "sha256-ZzHav/rQO5ITraJkDVTtf072uZ/Oh63jxxR0rhVN08w=";
    };

    nativeBuildInputs = with final; [
      poetry-core
      pythonRelaxDepsHook
    ];

    propagatedBuildInputs = with final; [
      anyio
      jsonpatch
      langsmith
      pydantic
      pyyaml
      tenacity
    ];

    pythonRelaxDeps = [ "langsmith" ];
    pythonImportsCheck = [ "langchain_core" ];

    meta = {
      description = "Building applications with LLMs through composability";
      homepage = "https://pypi.org/project/langchain-core/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  langchain = buildPythonPackage rec {
    pname = "langchain";
    version = "0.1.11";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "langchain-ai";
      repo = pname;
      rev = "refs/tags/v${version}";
      hash = "sha256-I7H8W85WJCt8Dkep5UvFRVuhJS8uAeg0xF9mNPZwm2g=";
    };
    sourceRoot = "source/libs/langchain";

    nativeBuildInputs = with prev; [
      poetry-core
    ];

    propagatedBuildInputs = with prev; [
      aiohttp
      anyio
      beautifulsoup4
      dataclasses-json
      google-api-core
      jinja2
      jsonpatch
      langchain-community
      langchain-core
      langchain-text-splitters
      langsmith
      numexpr
      numpy
      openai
      pexpect
      psutil
      pydantic
      pyowm
      pyyaml
      requests
      sqlalchemy
      tenacity
      tqdm
    ];

    passthru.optional-dependencies = with prev; {
      all = [
        aleph-alpha-client
        anthropic
        beautifulsoup4
        cohere
        deeplake
        elasticsearch
        faiss-cpu
        google-api-python-client
        google-search-results
        gptcache
        huggingface-hub
        jina
        jinja2
        manifest-ml
        networkx
        nlpcloud
        nltk
        nomic
        openai
        opensearch-py
        pgvector
        pinecone-client
        psycopg2-binary
        pypdf
        qdrant-client
        redis
        sentence-transformers
        spacy
        tensorflow-text
        tiktoken
        torch
        transformers
        weaviate-client
        wikipedia
        wolframalpha
      ];
      llms = [
        anthropic
        cohere
        huggingface-hub
        manifest-ml
        nlpcloud
        openai
        torch
        transformers
      ];
    };

    pythonImportsCheck = [ "langchain" ];

    meta = {
      description = "Building applications with LLMs through composability";
      homepage = "https://github.com/hwchase17/langchain";
      changelog = "https://github.com/hwchase17/langchain/releases/tag/v${version}";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  langchainhub = buildPythonPackage rec {
    pname = "langchainhub";
    version = "0.1.20";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-2lEgqctohfH9+vILhdTnxuUlNpo4nnCNIEF8P3YNySo=";
    };

    nativeBuildInputs = with prev; [
      poetry-core
    ];

    propagatedBuildInputs = with prev; [
      requests
      types-requests
    ];

    pythonImportsCheck = [ "langchainhub" ];

    meta = {
      description = "";
      homepage = "https://pypi.org/project/langchainhub/";
      license = licenses.unfree;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
