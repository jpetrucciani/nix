final: prev:
let
  inherit (prev) buildPythonPackage fetchPypi;
  inherit (prev.lib) licenses maintainers;
  inherit (prev.pkgs) fetchFromGitHub;
in
rec {
  langsmith = buildPythonPackage rec {
    pname = "langsmith";
    version = "0.1.2";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-gHxiDYccJ9DXq83J/wL6qW3zCOMtw2J95F3TD1WapY4=";
    };

    nativeBuildInputs = with prev; [
      poetry-core
    ];

    propagatedBuildInputs = with prev; [
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

  langchain-community = buildPythonPackage rec {
    pname = "langchain-community";
    version = "0.0.20";
    pyproject = true;

    src = fetchPypi {
      pname = "langchain_community";
      inherit version;
      hash = "sha256-xWxIvHfSTh/DmanummN9luOy/5UuOggLWkGCDZ0A+zw=";
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
    version = "0.1.24";
    pyproject = true;

    src = fetchPypi {
      pname = "langchain_core";
      inherit version;
      hash = "sha256-znD0uXaV61VjfgDuM9SA//xtsflXJvmbB2tVyxpCkn0=";
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
    version = "0.1.7";
    format = "pyproject";

    src = fetchFromGitHub {
      owner = "langchain-ai";
      repo = pname;
      rev = "refs/tags/v${version}";
      hash = "sha256-666ZqFGKx5379Kv+NAVaEW8ZyvlSsyQFB2egT+SUEcQ=";
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
    version = "0.1.13";
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
