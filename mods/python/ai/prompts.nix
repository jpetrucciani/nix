final: prev: with prev; {
  langchainplus-sdk = buildPythonPackage
    rec {
      pname = "langchainplus-sdk";
      version = "0.0.17";
      format = "pyproject";

      src = fetchPypi {
        pname = "langchainplus_sdk";
        inherit version;
        hash = "sha256-ZSDIZKI9ytvm+3IzoRc0f2rMMnJal3WOWTVHBMUN4wM=";
      };

      nativeBuildInputs = [
        poetry-core
      ];

      propagatedBuildInputs = [
        pydantic
        requests
        tenacity
      ];

      pythonImportsCheck = [ "langchainplus_sdk" ];

      meta = with lib; {
        description = "Client library to connect to the LangChainPlus LLM Tracing and Evaluation Platform";
        homepage = "https://www.langchain.plus";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  langchain = buildPythonPackage rec {
    pname = "langchain";
    version = "0.0.220";
    format = "pyproject";

    src = pkgs.fetchFromGitHub {
      owner = "hwchase17";
      repo = pname;
      rev = "refs/tags/v${version}";
      hash = "sha256-Br9j2mmLFxW3MHIY93m85mAVrvWVc6bnSlI71OwT8mY=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      aiohttp
      beautifulsoup4
      dataclasses-json
      jinja2
      langchainplus-sdk
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

    # gptcache was added as an optional dep, and it requires many other deps
    postPatch = ''
      sed -i -E '/gptcache =/d' pyproject.toml
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
    version = "0.6.38";
    format = "setuptools";

    src = prev.pkgs.fetchFromGitHub {
      owner = "jerryjliu";
      repo = "llama_index";
      rev = "refs/tags/v${version}";
      hash = "sha256-yKbA0LGP9YO/V4dUuFvCJeLaEs+42V7ZxXS5agITXFo=";
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
      "tests/indices/vector_store/test_faiss.py"
      "tests/indices/vector_store/test_pinecone.py"
      "tests/indices/vector_store/test_retrievers.py"
      "tests/indices/vector_store/test_simple.py"
      "tests/langchain_helpers/test_text_splitter.py"
      "tests/llm_predictor/vellum/test_predictor.py"
      "tests/llm_predictor/vellum/test_prompt_registry.py"
      "tests/objects/test_base.py"
      "tests/optimization/test_base.py"
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
