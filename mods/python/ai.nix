final: prev: with prev; rec {
  llama-cpp-python =
    let
      inherit (stdenv) isAarch64 isDarwin;
      osSpecific = with pkgs.darwin.apple_sdk.frameworks; if isDarwin then [ Accelerate ] ++ (if !isAarch64 then [ CoreGraphics CoreVideo ] else [ ]) else [ ];
      llama-cpp-pin = pkgs.fetchFromGitHub {
        owner = "ggerganov";
        repo = "llama.cpp";
        rev = "08737ef720f0510c7ec2aa84d7f70c691073c35d";
        hash = "sha256-rIjhmBNtBO3UAyXQ2ARqCoQVW5n6zuShvQUCoQwi0A0=";
      };
    in
    buildPythonPackage rec {
      pname = "llama-cpp-python";
      version = "0.1.50";

      format = "pyproject";
      src = pkgs.fetchFromGitHub {
        owner = "abetlen";
        repo = pname;
        rev = "v${version}";
        hash = "sha256-DbRhZksscLvFy9t77elF9M3paVd5U8M9UWD6yVgEMYI=";
      };

      preConfigure = ''
        cp -r ${llama-cpp-pin}/. ./vendor/llama.cpp
        chmod -R +w ./vendor/llama.cpp
      '';
      preBuild = ''
        cd ..
      '';
      buildInputs = osSpecific;

      nativeBuildInputs = [
        prev.pkgs.cmake
        prev.pkgs.ninja
        poetry-core
        scikit-build
        setuptools
      ];

      propagatedBuildInputs = [
        typing-extensions
      ];

      pythonImportsCheck = [ "llama_cpp" ];

      meta = with lib; {
        description = "A Python wrapper for llama.cpp";
        homepage = "https://github.com/abetlen/llama-cpp-python";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  geojson = prev.geojson.overridePythonAttrs {
    version = "2.5.0";
    src = fetchPypi {
      version = "2.5.0";
      pname = "geojson";
      hash = "sha256-bku3rOQiakXZyMixNIs/xDVAZYNZ+Tw/fgPvqfFfZYo=";
    };
    doCheck = false;
    pythonImportsCheck = [
      "geojson"
    ];
  };

  openapi-schema-pydantic = buildPythonPackage rec {
    pname = "openapi-schema-pydantic";
    version = "1.2.4";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-PiLPWLdKafdSzH5fFTf25EFkKC2ycAy7zTu5nd0GUZY=";
    };

    nativeBuildInputs = [
      setuptools
    ];

    propagatedBuildInputs = [
      pydantic
    ];

    pythonImportsCheck = [ "openapi_schema_pydantic" ];

    meta = with lib; {
      description = "OpenAPI (v3) specification schema as pydantic class";
      homepage = "https://pypi.org/project/openapi-schema-pydantic/1.2.4/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  hnswlib = buildPythonPackage rec {
    pname = "hnswlib";
    version = "0.7.0";

    src = pkgs.fetchFromGitHub {
      owner = "nmslib";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-XXz0NIQ5dCGwcX2HtbK5NFTalP0TjLO6ll6TmH3oflI=";
    };
    nativeBuildInputs = [
      pybind11
    ];
    propagatedBuildInputs = [
      numpy
      setuptools
    ];
    pythonImportsCheck = [
      "hnswlib"
    ];
    doCheck = false;
    meta = with lib; {
      description = "Header-only C++/python library for fast approximate nearest neighbors";
      homepage = "https://github.com/nmslib/hnswlib";
      changelog = "https://github.com/nmslib/hnswlib/releases/tag/v${version}";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  pymilvus = prev.pymilvus.overridePythonAttrs (_: rec {
    pname = "pymilvus";
    version = "2.2.6";
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-/i3WObwoY6Ffqw+Guij6+uGbKYKET2AJ+d708efmSx0=";
    };
    postPatch = "";
  });

  clickhouse-connect = buildPythonPackage rec {
    pname = "clickhouse-connect";
    version = "0.5.24";
    format = "setuptools";

    src = pkgs.fetchFromGitHub {
      owner = "ClickHouse";
      repo = pname;
      rev = "refs/tags/v${version}";
      hash = "sha256-Ff4E7zAPZt5vK/pOvw1S7doEOSgADrrUrjEUpk7cvgQ=";
    };

    nativeBuildInputs = [
      cython
      setuptools
    ];

    nativeCheckInputs = [
      pytestCheckHook
      pytest-mock
      sqlalchemy
    ];

    propagatedBuildInputs = [
      certifi
      clickhouse-driver
      lz4
      numpy
      pandas
      pytz
      urllib3
      zstandard
    ];

    preBuild = ''
      cythonize --inplace clickhouse_connect/driverc/{buffer,dataconv,npconv}.pyx
    '';

    passthru.optional-dependencies = {
      arrow = [
        pyarrow
      ];
      numpy = [
        numpy
      ];
      orjson = [
        orjson
      ];
      pandas = [
        pandas
      ];
      sqlalchemy = [
        sqlalchemy
      ];
      superset = [
        apache-superset
      ];
    };

    disabledTestPaths = [
      "examples/perf_test.py"
      "tests/integration_tests/*"
    ];

    pythonImportsCheck = [ "clickhouse_connect" ];

    meta = with lib; {
      description = "ClickHouse core driver, SqlAlchemy, and Superset libraries";
      homepage = "https://github.com/ClickHouse/clickhouse-connect";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  posthog = buildPythonPackage rec {
    pname = "posthog";
    version = "2.5.0";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-dgHvdbSD62emIpyv7ALaliT21G32EGZ3HKnj+YYoT8M=";
    };

    propagatedBuildInputs = [
      backoff
      monotonic
      python-dateutil
      requests
      setuptools
      six
    ];

    passthru.optional-dependencies = {
      dev = [
        black
        flake8
        flake8-print
        isort
        pre-commit
      ];
      sentry = [
        django
        sentry-sdk
      ];
      test = [
        coverage
        flake8
        freezegun
        mock
        pylint
        pytest
      ];
    };

    pythonImportsCheck = [ "posthog" ];

    meta = with lib; {
      description = "Integrate PostHog into any python application";
      homepage = "https://github.com/posthog/posthog-python";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  # gptcache = buildPythonPackage rec {
  #   pname = "gptcache";
  #   version = "0.1.10";
  #   format = "setuptools";

  #   src = pkgs.fetchFromGitHub {
  #     owner = "zilliztech";
  #     repo = pname;
  #     rev = version;
  #     hash = "sha256-3qwmd+H0ip3Jq1BqixKEBSKMxzYaKmh5rGBsPCo1ri4=";
  #   };

  #   propagatedBuildInputs = [
  #     cachetools
  #     chromadb
  #     faiss
  #     final.sqlalchemy_1
  #     hnswlib
  #     huggingface-hub
  #     numpy
  #     onnxruntime
  #     openai
  #     pydantic
  #     pymilvus
  #     transformers
  #   ];

  #   preBuild = ''
  #     substituteInPlace ./gptcache/utils/__init__.py --replace '_check_library("torch")' 'pass'
  #   '';

  #   pythonImportsCheck = [ "gptcache" ];

  #   meta = with lib; {
  #     description = "GPTCache, a powerful caching library for LLMs";
  #     homepage = "https://github.com/zilliztech/GPTCache";
  #     license = licenses.mit;
  #     maintainers = with maintainers; [ jpetrucciani ];
  #   };
  # };

  langchain = buildPythonPackage rec {
    pname = "langchain";
    version = "0.0.170";
    format = "pyproject";

    src = pkgs.fetchFromGitHub {
      owner = "hwchase17";
      repo = pname;
      rev = "refs/tags/v${version}";
      hash = "sha256-0hV8X1c+vMJlynNud//hb164oTYmYlsmeSM4dKwC0G4=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      sqlalchemy
      aiohttp
      dataclasses-json
      jinja2
      numexpr
      numpy
      openai
      openapi-schema-pydantic
      pexpect
      pydantic
      pyowm
      pyyaml
      requests
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
      ${pkgs.gnused}/bin/sed -i -E '/gptcache =/d' pyproject.toml
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
    version = "0.6.7";
    format = "setuptools";

    src = prev.pkgs.fetchFromGitHub {
      owner = "jerryjliu";
      repo = "llama_index";
      rev = "refs/tags/v${version}";
      hash = "sha256-CPUotMJxt7s86CvaIurBKLYYkjCSx0rNDG4KdUccVZ0=";
    };

    nativeCheckInputs = [
      pytestCheckHook
      nltk
      pillow
    ];

    propagatedBuildInputs = [
      faiss
      langchain
      numpy
      openai
      pandas
      tiktoken
    ];

    disabledTestPaths = [
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
      "tests/indices/struct_store/test_base.py"
      "tests/indices/struct_store/test_pandas.py"
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
      "tests/optimization/test_base.py"
      "tests/playground/test_base.py"
      "tests/selectors/test_llm_selectors.py"
      "tests/test_utils.py"
      "tests/token_predictor/test_base.py"
    ];

    pythonImportsCheck = [ "llama_index" ];

    meta = with lib; {
      description = "Interface between LLMs and your data";
      homepage = "https://github.com/jerryjliu/llama_index";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  accelerate = buildPythonPackage rec {
    pname = "accelerate";
    version = "0.18.0";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-HdNv2XLeSm0M/+Xk1tMGIv2FN2X3c7VYLPB5be7+EBY=";
    };

    propagatedBuildInputs = [
      numpy
      packaging
      psutil
      pyyaml
      torch
    ];

    passthru.optional-dependencies = {
      dev = [
        black
        datasets
        deepspeed
        evaluate
        hf-doc-builder
        parameterized
        pytest
        pytest-subtests
        pytest-xdist
        rich
        ruff
        scikit-learn
        scipy
        tqdm
        transformers
      ];
      quality = [
        black
        hf-doc-builder
        ruff
      ];
      rich = [
        rich
      ];
      sagemaker = [
        sagemaker
      ];
      test_dev = [
        datasets
        deepspeed
        evaluate
        scikit-learn
        scipy
        tqdm
        transformers
      ];
      test_prod = [
        parameterized
        pytest
        pytest-subtests
        pytest-xdist
      ];
      test_trackers = [
        comet-ml
        tensorboard
        wandb
      ];
      testing = [
        datasets
        deepspeed
        evaluate
        parameterized
        pytest
        pytest-subtests
        pytest-xdist
        scikit-learn
        scipy
        tqdm
        transformers
      ];
    };

    pythonImportsCheck = [ "accelerate" ];

    meta = with lib; {
      description = "Accelerate";
      homepage = "https://github.com/huggingface/accelerate";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  peft = buildPythonPackage rec {
    pname = "peft";
    version = "0.2.0";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-zjP0hMcDgZBwW2nk0iiSMMfBgZwQhHgUg6yOEY8Kca8=";
    };

    propagatedBuildInputs = [
      accelerate
      numpy
      packaging
      psutil
      pyyaml
      torch
      transformers
    ];

    passthru.optional-dependencies = {
      dev = [
        black
        hf-doc-builder
        ruff
      ];
      docs_specific = [
        hf-doc-builder
      ];
      quality = [
        black
        ruff
      ];
    };

    pythonImportsCheck = [ "peft" ];

    meta = with lib; {
      description = "Parameter-Efficient Fine-Tuning (PEFT";
      homepage = "https://github.com/huggingface/peft";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  pyllamacpp =
    let
      inherit (stdenv) isAarch64 isDarwin;
      osSpecific = with pkgs.darwin.apple_sdk.frameworks; if isDarwin then [ Accelerate ] ++ (if !isAarch64 then [ CoreGraphics CoreVideo ] else [ ]) else [ ];
    in
    buildPythonPackage rec {
      pname = "pyllamacpp";
      version = "2.1.3";
      format = "pyproject";

      src = pkgs.fetchFromGitHub {
        owner = "abdeladim-s";
        repo = pname;
        rev = "refs/tags/v${version}";
        hash = "sha256-APDOsSGI3QOd+h+7ZAVbXM5m8DKilF0UmbdIvU1FcIA=";
        fetchSubmodules = true;
      };
      buildInputs = osSpecific;
      nativeBuildInputs = [
        pkgs.cmake
        pkgs.ninja
        setuptools
        wheel
      ];

      pythonImportsCheck = [ "pyllamacpp" ];
      dontUseCmakeConfigure = true;

      meta = with lib; {
        description = "Python bindings for llama.cpp";
        homepage = "https://github.com/abdeladim-s/pyllamacpp";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  pygptj =
    let
      inherit (stdenv) isAarch64 isDarwin;
      osSpecific = with pkgs.darwin.apple_sdk.frameworks; if isDarwin then [ Accelerate ] ++ (if !isAarch64 then [ CoreGraphics CoreVideo ] else [ ]) else [ ];
    in
    buildPythonPackage rec {
      pname = "pygptj";
      version = "2.0.3";
      format = "pyproject";

      src = pkgs.fetchFromGitHub {
        owner = "abdeladim-s";
        repo = pname;
        rev = "refs/tags/v${version}";
        hash = "sha256-Ub7qXARiOIpT4UaI9mACtrRUiPbIQgABUias3TNDqP0=";
        fetchSubmodules = true;
      };

      buildInputs = osSpecific;
      nativeBuildInputs = [
        pkgs.cmake
        pkgs.ninja
        setuptools
        wheel
      ];

      dontUseCmakeConfigure = true;

      propagatedBuildInputs = [
        numpy
      ];

      pythonImportsCheck = [ "pygptj" ];

      meta = with lib; {
        description = "Python bindings for the GGML GPT-J Laguage model";
        homepage = "https://github.com/abdeladim-s/pygptj";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  pygpt4all = buildPythonPackage rec {
    pname = "pygpt4all";
    version = "1.1.0";
    format = "setuptools";

    src = pkgs.fetchFromGitHub {
      owner = "nomic-ai";
      repo = pname;
      rev = "refs/tags/v${version}";
      hash = "sha256-4/AogNqSv2bBugkXj4T5G6xgr2tubZNkBpUu/CUDYko=";
    };

    pythonImportsCheck = [ "pygpt4all" ];
    propagatedBuildInputs = [
      pyllamacpp
      pygptj
    ];

    meta = with lib; {
      description = "Official Python CPU inference for GPT4All language models based on llama.cpp and ggml";
      homepage = "https://github.com/nomic-ai/pygpt4all";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  chromadb = buildPythonPackage rec {
    pname = "chromadb";
    version = "0.3.23";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-h/qSLJLi6Q+0gjS0NenU8MYWRvvRUmBi9T9jMm/CEig=";
    };

    nativeBuildInputs = [
      setuptools
      setuptools-scm
    ];

    propagatedBuildInputs = [
      clickhouse-connect
      duckdb
      fastapi
      hnswlib
      httptools
      numpy
      pandas
      posthog
      pydantic
      python-dotenv
      requests
      sentence-transformers
      typing-extensions
      uvicorn
      uvloop
      watchfiles
      websockets
    ];

    pythonImportsCheck = [ "chromadb" ];

    meta = with lib; {
      description = "the AI-native open-source embedding database ";
      homepage = "https://github.com/chroma-core/chroma";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  langcorn = buildPythonPackage rec {
    pname = "langcorn";
    version = "0.0.7";
    format = "pyproject";

    src = pkgs.fetchFromGitHub {
      owner = "msoedov";
      repo = pname;
      rev = "refs/tags/${version}";
      hash = "sha256-Oo8yVVLnlq/uOkWorqgbMMwmwIbiGTNIVFb1HUm9GTE=";
    };

    postPatch = ''
      ${pkgs.gnused}/bin/sed -i -E \
        -e '/bs4 =/d' \
        -e '/loguru =/d' \
        -e 's#(langchain = )"\^0.0.163"#\1">0.0.163"#g' \
        -e 's#(uvicorn = )"\^0.22.0"#\1">=0.20.0"#g' \
        pyproject.toml
    '';

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      fastapi
      fire
      langchain
      loguru
      openai
      uvicorn
    ];

    pythonImportsCheck = [ "langcorn" ];

    meta = with lib; {
      description = "A Python package creating rest api interface for LangChain";
      homepage = "https://github.com/msoedov/langcorn";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
