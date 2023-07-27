final: prev: with prev; rec {
  langsmith = buildPythonPackage rec {
    pname = "langsmith";
    version = "0.0.15";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-xePSzFCi9vXEqvP4mYol+F3ZSzzQFrxJmb5RAAyTOz8=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      pydantic
      requests
    ];

    pythonImportsCheck = [ "langsmith" ];

    meta = with lib; {
      description = "Client library to connect to the LangChainPlus LLM Tracing and Evaluation Platform";
      homepage = "https://www.langchain.plus";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  langchain = buildPythonPackage rec {
    pname = "langchain";
    version = "0.0.244";
    format = "pyproject";

    src = pkgs.fetchFromGitHub {
      owner = "hwchase17";
      repo = pname;
      rev = "refs/tags/v${version}";
      hash = "sha256-yiSkQ6dkJQxlDKqFKaCcAm+Fa/9FnXos4UYehMnrN1c=";
    };
    sourceRoot = "source/libs/langchain";

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      aiohttp
      beautifulsoup4
      dataclasses-json
      jinja2
      langsmith
      numexpr
      numpy
      openai
      openapi-schema-pydantic
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

    passthru.optional-dependencies = {
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
        # gptcache
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

    postPatch = ''
      sed -i -E '/gptcache/d' ./pyproject.toml
    '';

    pythonImportsCheck = [ "langchain" ];

    meta = with lib; {
      description = "Building applications with LLMs through composability";
      homepage = "https://github.com/hwchase17/langchain";
      changelog = "https://github.com/hwchase17/langchain/releases/tag/v${version}";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  llama-index = buildPythonPackage rec {
    pname = "llama-index";
    version = "0.7.13";
    format = "setuptools";

    src = prev.pkgs.fetchFromGitHub {
      owner = "jerryjliu";
      repo = "llama_index";
      rev = "refs/tags/v${version}";
      hash = "sha256-aZ2FRPpfNmy3gMd2bAu5kLTonISorT4e2x4WzVRdhFc=";
    };

    nativeCheckInputs = [
      pytestCheckHook
      pythonRelaxDepsHook
      nltk
      pillow
    ];

    pythonRelaxDeps = [
      "fsspec"
      "sqlalchemy"
    ];

    propagatedBuildInputs = [
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
      "tests/callbacks/test_token_counter.py"
      "tests/chat_engine/test_condense_question.py"
      "tests/chat_engine/test_simple.py"
      "tests/embeddings/test_base.py"
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
      "tests/langchain_helpers/test_text_splitter.py"
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
      "tests/token_predictor/test_base.py"
      "tests/tools/test_ondemand_loader.py"
    ];

    pythonImportsCheck = [ "llama_index" ];

    meta = with lib; {
      description = "Interface between LLMs and your data";
      homepage = "https://github.com/jerryjliu/llama_index";
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

      src = pkgs.fetchFromGitHub {
        owner = "microsoft";
        repo = name;
        rev = "refs/tags/${version}";
        hash = "sha256-tQpDJprxctKI88F+CZ9aSJbVo7tjmI4+VrI+WO4QlxE=";
      };

      postPatch = ''
        sed -i -E '/gptcache/d' setup.py
      '';

      propagatedBuildInputs = [
        aiohttp
        diskcache
        # gptcache
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

      nativeCheckInputs = [
        pytestCheckHook
        torch
        transformers
      ];

      passthru.optional-dependencies = {
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

      meta = with lib; {
        description = "A guidance language for controlling large language models";
        homepage = "https://github.com/microsoft/guidance";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };
}
