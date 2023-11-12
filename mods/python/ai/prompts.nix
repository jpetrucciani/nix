final: prev:
let
  inherit (prev) buildPythonPackage fetchPypi;
  inherit (prev.lib) licenses maintainers;
  inherit (prev.pkgs) fetchFromGitHub;
in
rec {
  langsmith = buildPythonPackage rec {
    pname = "langsmith";
    version = "0.0.63";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-3bLfrfrT4FFR7YuhZD0cUWAkuA+9DGJjAkQAztBqN2g=";
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

  langchain = buildPythonPackage rec {
    pname = "langchain";
    version = "0.0.335";
    format = "pyproject";

    src = fetchFromGitHub {
      owner = "langchain-ai";
      repo = pname;
      rev = "refs/tags/v${version}";
      hash = "sha256-xhvtKOreRSA0zWQtSL0wZq2mzo8P47j55DtO/Sxg1Oo=";
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

  llama-index = buildPythonPackage rec {
    pname = "llama-index";
    version = "0.8.68";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "run-llama";
      repo = "llama_index";
      rev = "refs/tags/v${version}";
      hash = "sha256-X5xicAl2CXlvPja9aRm+UjNS9+J8t+jxnsiOKR/QD/k=";
    };

    nativeBuildInputs = with prev; [
      pythonRelaxDepsHook
      poetry-core
    ];
    nativeCheckInputs = with prev; [
      pytestCheckHook
      nltk
      pillow
    ];

    pythonRelaxDeps = [
      "fsspec"
      "langchain"
      "sqlalchemy"
    ];

    propagatedBuildInputs = with prev; [
      beautifulsoup4
      faiss
      fsspec
      langchain
      nest-asyncio
      numpy
      openai
      pandas
      sqlalchemy
      tiktoken
      vellum-ai
    ];

    disabledTestPaths = [
      "tests/agent/openai/test_openai_agent.py"
      "tests/agent/react/test_react_agent.py"
      "tests/callbacks/test_token_counter.py"
      "tests/chat_engine/test_condense_question.py"
      "tests/chat_engine/test_simple.py"
      "tests/embeddings/test_base.py"
      "tests/embeddings/test_utils.py"
      "tests/indices/document_summary/test_index.py"
      "tests/indices/document_summary/test_retrievers.py"
      "tests/indices/empty/test_base.py"
      "tests/indices/keyword_table/test_base.py"
      "tests/indices/keyword_table/test_retrievers.py"
      "tests/indices/keyword_table/test_utils.py"
      "tests/indices/knowledge_graph/test_base.py"
      "tests/indices/knowledge_graph/test_retrievers.py"
      "tests/indices/list/test_index.py"
      "tests/indices/list/test_retrievers.py"
      "tests/indices/postprocessor/test_base.py"
      "tests/indices/postprocessor/test_llm_rerank.py"
      "tests/indices/postprocessor/test_optimizer.py"
      "tests/indices/query/query_transform/test_base.py"
      "tests/indices/query/test_compose_vector.py"
      "tests/indices/query/test_compose.py"
      "tests/indices/query/test_query_bundle.py"
      "tests/indices/response/test_response_builder.py"
      "tests/indices/response/test_tree_summarize.py"
      "tests/indices/struct_store/test_base.py"
      "tests/indices/struct_store/test_json_query.py"
      "tests/indices/struct_store/test_sql_query.py"
      "tests/indices/test_loading_graph.py"
      "tests/indices/test_loading.py"
      "tests/indices/test_node_utils.py"
      "tests/indices/test_prompt_helper.py"
      "tests/indices/test_utils.py"
      "tests/indices/tree/test_embedding_retriever.py"
      "tests/indices/tree/test_index.py"
      "tests/indices/tree/test_retrievers.py"
      "tests/indices/vector_store/test_deeplake.py"
      "tests/indices/vector_store/test_faiss.py"
      "tests/indices/vector_store/test_pinecone.py"
      "tests/indices/vector_store/test_retrievers.py"
      "tests/indices/vector_store/test_simple.py"
      "tests/llm_predictor/vellum/test_predictor.py"
      "tests/llm_predictor/vellum/test_prompt_registry.py"
      "tests/llms/test_openai.py"
      "tests/llms/test_palm.py"
      "tests/memory/test_chat_memory_buffer.py"
      "tests/objects/test_base.py"
      "tests/playground/test_base.py"
      "tests/query_engine/test_pandas.py"
      "tests/question_gen/test_llm_generators.py"
      "tests/selectors/test_llm_selectors.py"
      "tests/test_utils.py"
      "tests/text_splitter/test_code_splitter.py"
      "tests/text_splitter/test_sentence_splitter.py"
      "tests/token_predictor/test_base.py"
      "tests/tools/test_ondemand_loader.py"
    ];

    # pythonImportsCheck = [ "llama_index" ];
    doCheck = false;

    meta = {
      description = "Interface between LLMs and your data";
      homepage = "https://github.com/jerryjliu/llama_index";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  llama-hub = buildPythonPackage rec {
    pname = "llama-hub";
    version = "0.0.38";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "run-llama";
      repo = pname;
      rev = "refs/tags/v${version}";
      hash = "sha256-e0TbuVjgimDj/7BYYOZ7gsUBSF9m+zHgaO/PPA6Fq5Y=";
    };

    postPatch = ''
      sed -i -E 's#(poetry)>=0.12#\1-core#g' ./pyproject.toml
      substituteInPlace ./pyproject.toml --replace "poetry.masonry.api" "poetry.core.masonry.api"
    '';

    nativeBuildInputs = with prev; [
      poetry-core
    ];

    propagatedBuildInputs = with prev; [
      atlassian-python-api
      html2text
      llama-index
      psutil
      retrying
    ];

    pythonImportsCheck = [ "llama_hub" ];

    meta = {
      description = "A library of community-driven data loaders for LLMs. Use with LlamaIndex and/or LangChain";
      homepage = "https://github.com/run-llama/llama-hub";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  guidance =
    let
      name = "guidance";
      version = "0.0.64";
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
