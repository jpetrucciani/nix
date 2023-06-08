final: prev: with prev; let
  inherit (stdenv) isAarch64 isDarwin;
  inherit (prev.pkgs) darwin;
  isM1 = isDarwin && isAarch64;
in
rec {
  llama-cpp-python =
    let
      osSpecific =
        if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate MetalKit MetalPerformanceShaders MetalPerformanceShadersGraph ]
        else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
        else [ ];
      llama-cpp-pin = pkgs.fetchFromGitHub {
        owner = "ggerganov";
        repo = "llama.cpp";
        rev = "ffb06a345e3a9e30d39aaa5b46a23201a74be6de";
        hash = "sha256-tludsc/R841nUUAsGXrMEGMX3vfoG4Lci3MNGOWJTPI=";
      };
    in
    buildPythonPackage rec {
      pname = "llama-cpp-python";
      version = "0.1.57";

      format = "pyproject";
      src = pkgs.fetchFromGitHub {
        owner = "abetlen";
        repo = pname;
        rev = "refs/tags/v${version}";
        hash = "sha256-BrR3N+3KRu96j0MIydyrvFb2BN3COeBPISac+ixq3XM=";
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
        numpy
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

  langchainplus-sdk = buildPythonPackage
    rec {
      pname = "langchainplus-sdk";
      version = "0.0.4";
      format = "pyproject";

      src = fetchPypi {
        pname = "langchainplus_sdk";
        inherit version;
        hash = "sha256-DAmvYugZdeM1YcZVupsyd315g0IYyTd9KFeKlVh0AEQ=";
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
    version = "0.0.193";
    format = "pyproject";

    src = pkgs.fetchFromGitHub {
      owner = "hwchase17";
      repo = pname;
      rev = "refs/tags/v${version}";
      hash = "sha256-Qg6kFFPOk+XpLzEl3YSI9I4fPq9KB4UtQf9Khgut7FE=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      sqlalchemy
      aiohttp
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

  vellum-ai = buildPythonPackage rec {
    pname = "vellum-ai";
    version = "0.0.15";
    format = "pyproject";

    src = fetchPypi {
      pname = "vellum_ai";
      inherit version;
      hash = "sha256-bZIUe1z05tlmCFOOmXc6MZuZhQR+duXzfH+6YXdrzog=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      httpx
      pydantic
    ];

    pythonImportsCheck = [ "vellum" ];

    meta = with lib; {
      description = "";
      homepage = "https://www.vellum.ai/";
      license = with licenses; [ ];
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  llama-index = buildPythonPackage rec {
    pname = "llama-index";
    version = "0.6.21";
    format = "setuptools";

    src = prev.pkgs.fetchFromGitHub {
      owner = "jerryjliu";
      repo = "llama_index";
      rev = "refs/tags/v${version}";
      hash = "sha256-dROt6RtShBZksFGHGULOGq4i8Q0d17vTJPMcmYylNqg=";
    };

    postPatch = ''
      sed -i -E \
        -e 's#(fsspec>=)2023.5.0#\12023.4.0#g' \
        -e 's#(sqlalchemy>=)2.0.15#\12.0.0#g' \
        setup.py
    '';

    nativeCheckInputs = [
      pytestCheckHook
      nltk
      pillow
    ];

    propagatedBuildInputs = [
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
      "tests/indices/struct_store/test_base.py"
      "tests/indices/struct_store/test_json_query.py"
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
      "tests/llm_predictor/vellum/test_predictor.py"
      "tests/llm_predictor/vellum/test_prompt_registry.py"
      "tests/optimization/test_base.py"
      "tests/playground/test_base.py"
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

  pyllamacpp =
    let
      osSpecific =
        if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate ]
        else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
        else [ ];
    in
    buildPythonPackage rec {
      pname = "pyllamacpp";
      version = "2.4.0";
      format = "pyproject";

      src = pkgs.fetchFromGitHub {
        owner = "abdeladim-s";
        repo = pname;
        rev = "refs/tags/v${version}";
        hash = "sha256-EFV9/JNqsUYU76DxaaDpiFcCchXk/nR6TQvn3Z+Z8KE=";
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
      isM1 = isDarwin && isAarch64;
      osSpecific =
        if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate ]
        else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
        else [ ];
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

  chromadb =
    let
      inherit (stdenv) isDarwin;
    in
    buildPythonPackage rec {
      pname = "chromadb";
      version = "0.3.25";
      format = "pyproject";

      src = fetchPypi {
        inherit pname version;
        hash = "sha256-ePNcZd58IWIt/A/gK222tZuo8E+4uM17Xl+PaPmAboo=";
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
        overrides
        pandas
        posthog
        pydantic
        python-dotenv
        requests
        sentence-transformers
        tqdm
        typing-extensions
        uvicorn
        uvloop
        watchfiles
        websockets
      ] ++ (if !isDarwin then [ onnxruntime ] else [ ]);

      postPatch =
        let
          onnx_patch = if isDarwin then "/onnxruntime/d" else "s#(onnxruntime) >= (1.14.1)#\1 >= 1.13.1#g";
        in
        ''
          sed -i -E \
            -e '${onnx_patch}' \
            -e 's#(tqdm) >= (4.65.0)#\1 >= 4.64.1#g' \
            pyproject.toml
        '';

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
      sed -i -E \
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

  rwkv-cpp =
    let
      osSpecific =
        if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate ]
        else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
        else [ ];
      version = "0.0.1";
      libFile = if isDarwin then "librwkv.dylib" else "librwkv.so";
      setup-py = pkgs.writeTextFile {
        name = "setup.py";
        text = ''
          from setuptools import setup
          setup(
            name="rwkv_cpp",
            version="${version}",
            author="",
            author_email="",
            packages=["."],
            package_data={"":["${libFile}"]},
            setup_requires=["numpy", "torch", "tokenizers"],
            install_requires=[],
          )
        '';
      };
    in
    buildPythonPackage {
      inherit version;
      pname = "rwkv-cpp";
      format = "pyproject";
      src = pkgs.fetchFromGitHub {
        owner = "saharNooby";
        repo = "rwkv.cpp";
        rev = "1c363e6d5f4ec7817ceffeeb17bd972b1ce9d9d0";
        hash = "sha256-IU+3MwIY3NnJPYtxrgpphLOnHAOQAKYd+8BV1tusgC4=";
        fetchSubmodules = true;
      };
      preBuild = ''
        cd ..
        cp ./rwkv/rwkv_cpp_model.py .
        cp ./rwkv/rwkv_cpp_shared_library.py .
        cp ${setup-py} ./setup.py
        mkdir -p ./bin/Release
        cmake .
        cmake --build . --config Release
        sed -i -E "s#(paths = \[)#\1'$out/${prev.python.sitePackages}/${libFile}',#g" ./rwkv_cpp_shared_library.py
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
        numpy
        tokenizers
        torch
        typing-extensions
      ];

      pythonImportsCheck = [
        "rwkv_cpp_model"
        "rwkv_cpp_shared_library"
      ];

      meta = with lib; {
        description = "";
        homepage = "https://github.com/saharNooby/rwkv.cpp";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  strip-tags = buildPythonPackage rec {
    pname = "strip-tags";
    version = "0.3";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-SWTRs/+ueQTzmkAbFa/PGjzml3CIh/nG09TRJogPzoY=";
    };

    propagatedBuildInputs = [
      beautifulsoup4
      click
      html5lib
    ];

    passthru.optional-dependencies = {
      test = [
        pytest
      ];
    };

    pythonImportsCheck = [ "strip_tags" ];

    meta = with lib; {
      description = "Strip tags from HTML, optionally from areas identified by CSS selectors";
      homepage = "hhttps://github.com/simonw/strip-tags";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  ttok = buildPythonPackage rec {
    pname = "ttok";
    version = "0.1";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-i5Q59xviIuEXOSssizi7lOQWNBzLk4GRpWWJ7DNTlRo=";
    };

    propagatedBuildInputs = [
      click
      tiktoken
    ];

    passthru.optional-dependencies = {
      test = [
        cogapp
        pytest
      ];
    };

    pythonImportsCheck = [ "ttok" ];

    meta = with lib; {
      description = "Count and truncate text based on tokens";
      homepage = "https://github.com/simonw/ttok";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  whisper-cpp-python =
    let
      name = "whisper-cpp-python";
      version = "0.2.0";
      osSpecific =
        if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate ]
        else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
        else [ ];
    in
    buildPythonPackage {
      inherit version;
      pname = name;
      format = "pyproject";

      src = pkgs.fetchFromGitHub {
        owner = "carloscdias";
        repo = name;
        rev = "0744238e10f6b1da3440d43aa3dff43d46b09b30";
        hash = "sha256-Nj35UwCLD88SF26rqrNiLo1lUQTHAKUVKyMyaA0Cy7Q=";
        fetchSubmodules = true;
      };

      postPatch = let sed = "sed -i -E"; in ''
        ${sed} 's#(librosa = )"\^0.10.0.post2"#\1">=0.10.0"#g' ./pyproject.toml
        ${sed} 's#(librosa>=)0.10.0.post2#\10.10.0#g' ./setup.py
      '' + (if stdenv.isDarwin then ''
        ${sed} 's#(_lib_base_name = )"whisper"#\1"libwhisper"#g' ./setup.py
        ${sed} 's#(lib_ext = )".so"#\1".dylib"#g' ./setup.py
      '' else "");
      preBuild = ''
        cd ..
      '';
      buildInputs = osSpecific;

      nativeBuildInputs = [
        pkgs.cmake
        pkgs.ninja
        pycparser
        scikit-build
        setuptools
      ] ++ (if stdenv.isDarwin then [ pkgs.gcc ] else [ ]);

      propagatedBuildInputs = [
        librosa
      ];

      pythonImportsCheck = [ "whisper_cpp_python" ];

      meta = with lib; {
        description = "A Python wrapper for whisper.cpp";
        homepage = "https://github.com/carloscdias/whisper-cpp-python";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  ctransformers =
    let
      name = "ctransformers";
      version = "0.2.1";
      osSpecific =
        if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate ]
        else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
        else [ ];
    in
    buildPythonPackage {
      inherit version;
      pname = name;
      format = "setuptools";

      src = pkgs.fetchFromGitHub {
        owner = "marella";
        repo = name;
        rev = "refs/tags/v${version}";
        hash = "sha256-+jBNK/Cv8O0vmGCuc8Ec+rRDMSufHfG8SToIX2N+exQ=";
        fetchSubmodules = true;
      };

      propagatedBuildInputs = [
        huggingface-hub
      ];
      dontUseCmakeConfigure = true;

      nativeBuildInputs = [ pkgs.cmake ];
      buildInputs = osSpecific;
      nativeCheckInputs = [ pytestCheckHook ];
      pythonImportsCheck = [ "ctransformers" ];
      disabledTestPaths = [ "tests/test_model.py" ];
      pytestFlagsArray = [ "--lib basic" ];
      meta = with lib; {
        description = "Python bindings for the Transformer models implemented in C/C++ using GGML library";
        homepage = "https://github.com/marella/ctransformers";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  diffusers = buildPythonPackage rec {
    pname = "diffusers";
    version = "0.16.1";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-TNdAA4LIbYXghCVVDeGxqB1O0DYj+9S82Dd4ZNnEbv4=";
    };

    propagatedBuildInputs = [
      filelock
      huggingface-hub
      importlib-metadata
      numpy
      pillow
      regex
      requests
      setuptools
    ];

    passthru.optional-dependencies = {
      dev = [
        accelerate
        black
        compel
        datasets
        flax
        hf-doc-builder
        isort
        jax
        jaxlib
        jinja2
        k-diffusion
        librosa
        note-seq
        parameterized
        protobuf
        pytest
        pytest-timeout
        pytest-xdist
        requests-mock
        ruff
        safetensors
        scipy
        sentencepiece
        tensorboard
        torch
        torchvision
        transformers
      ];
      docs = [
        hf-doc-builder
      ];
      flax = [
        flax
        jax
        jaxlib
      ];
      quality = [
        black
        hf-doc-builder
        isort
        ruff
      ];
      test = [
        compel
        datasets
        jinja2
        k-diffusion
        librosa
        note-seq
        parameterized
        pytest
        pytest-timeout
        pytest-xdist
        requests-mock
        safetensors
        scipy
        sentencepiece
        torchvision
        transformers
      ];
      torch = [
        accelerate
        torch
      ];
      training = [
        accelerate
        datasets
        jinja2
        protobuf
        tensorboard
      ];
    };

    pythonImportsCheck = [ "diffusers" ];

    meta = with lib; {
      description = "State-of-the-art diffusion models for image and audio generation in PyTorch";
      homepage = "https://github.com/huggingface/diffusers";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  analytics-python = buildPythonPackage rec {
    pname = "analytics-python";
    version = "1.4.0";

    disabled = pythonOlder "3.6";

    src = fetchPypi {
      inherit pname version;
      sha256 = "plFBq25H2zlvW8Vwix25P/mpmILYH+gIIor9Xrtt/l8=";
    };

    postPatch = ''
      substituteInPlace setup.py \
        --replace '"backoff==1.10.0"' '"backoff>=1.10.0,<3"'
    '';

    propagatedBuildInputs = [
      monotonic
      requests
      backoff
      python-dateutil
    ];

    # Almost all tests run against a hosted API, and the few that are mocked are hard to cherry-pick
    doCheck = false;

    pythonImportsCheck = [
      "analytics"
      "analytics.client"
      "analytics.consumer"
      "analytics.request"
      "analytics.utils"
      "analytics.version"
    ];

    meta = with lib; {
      homepage = "https://segment.com/libraries/python";
      description = "Hassle-free way to integrate analytics into any python application";
      license = licenses.mit;
      maintainers = with maintainers; [ pbsds ];
    };
  };

  ffmpy = buildPythonPackage rec {
    pname = "ffmpy";
    version = "0.3.0";

    disabled = pythonOlder "3.6";

    # The github repo has no release tags, the pypi distribution has no tests.
    # This package is quite trivial anyway, and the tests mainly play around with the ffmpeg cli interface.
    # https://github.com/Ch00k/ffmpy/issues/60
    src = fetchPypi {
      inherit pname version;
      sha256 = "dXWRWB7uJbSlCsn/ubWANaJ5RTPbR+BRL1P7LXtvmtw=";
    };

    propagatedBuildInputs = [
      pkgs.ffmpeg
    ];

    pythonImportsCheck = [ "ffmpy" ];

    meta = with lib; {
      description = "A simple python interface for FFmpeg/FFprobe";
      homepage = "https://github.com/Ch00k/ffmpy";
      license = licenses.mit;
      maintainers = with maintainers; [ pbsds ];
    };
  };

  gradio-client = buildPythonPackage rec {
    pname = "gradio-client";
    version = "0.2.6";
    format = "pyproject";

    src = fetchPypi {
      pname = "gradio_client";
      inherit version;
      hash = "sha256-pdXFeZzjOuMQfh0wmSwnBQ9QUG8V3XBIGjmxOsR+JhM=";
    };

    nativeBuildInputs = [
      hatch-fancy-pypi-readme
      hatch-requirements-txt
      hatchling
    ];

    propagatedBuildInputs = [
      fsspec
      httpx
      huggingface-hub
      packaging
      requests
      typing-extensions
      websockets
    ];

    pythonImportsCheck = [ "gradio_client" ];

    meta = with lib; {
      description = "Python library for easily interacting with trained machine learning models";
      homepage = "https://github.com/gradio-app/gradio";
      license = licenses.asl20;
      maintainers = with maintainers; [ ];
    };
  };

  gradio = buildPythonPackage rec {
    pname = "gradio";
    version = "3.33.1";
    disabled = pythonOlder "3.7";
    format = "pyproject";

    # We use the Pypi release, as it provides prebuild webui assets,
    # and its releases are also more frequent than github tags
    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-55AzaSYGuUXcwryPOKPNLDoazTcIc2UhXBuwCtf3aqM=";
    };

    nativeBuildInputs = [
      hatchling
      hatch-requirements-txt
      hatch-fancy-pypi-readme
    ];
    propagatedBuildInputs = [
      altair
      aiohttp
      aiofiles
      analytics-python
      fastapi
      ffmpy
      gradio-client
      matplotlib
      numpy
      orjson
      pandas
      paramiko
      pillow
      pycryptodome
      python-multipart
      pydub
      requests
      uvicorn
      jinja2
      fsspec
      httpx
      pydantic
      semantic-version
      websockets
      markdown-it-py
      mdit-py-plugins
      linkify-it-py
    ];

    postPatch = ''
      # Unpin h11, as its version was only pinned to aid dependency resolution.
      # Basically a revert of https://github.com/gradio-app/gradio/pull/1680
      substituteInPlace requirements.txt \
        --replace "h11<0.13,>=0.11" "" \
        --replace "mdit-py-plugins<=0.3.3" "mdit-py-plugins>=0.3.3"
    '';

    doCheck = false;

    meta = with lib; {
      homepage = "https://www.gradio.app/";
      description = "Python library for easily interacting with trained machine learning models";
    };
  };

  flaskwebgui = buildPythonPackage {
    pname = "flaskwebgui";
    version = "1.0.6";
    format = "setuptools";

    src = pkgs.fetchFromGitHub {
      owner = "ClimenteA";
      repo = "flaskwebgui";
      rev = "b77555b9a795dfd7154c5116f7dfde5ce238e99b";
      hash = "sha256-7+/WAwhY70nXFpK+2EnCkdGBBqTwq60HDcCpC35iSvE=";
    };

    propagatedBuildInputs = [
      psutil
    ];

    pythonImportsCheck = [ "flaskwebgui" ];

    meta = with lib; {
      description = "Create desktop applications with Flask/Django/FastAPI";
      homepage = "https://github.com/ClimenteA/flaskwebgui";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  simple-websocket = buildPythonPackage rec {
    pname = "simple-websocket";
    version = "0.10.0";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-gsCwsQBtVJDwn/ZjkjlNkN11goVjXtrSQeCT6air0+s=";
    };

    nativeBuildInputs = [
      setuptools
      wheel
    ];

    propagatedBuildInputs = [
      wsproto
    ];

    pythonImportsCheck = [ "simple_websocket" ];

    meta = with lib; {
      description = "Simple WebSocket server and client for Python";
      homepage = "https://github.com/miguelgrinberg/simple-websocket";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  controlnet-aux = buildPythonPackage rec {
    pname = "controlnet-aux";
    version = "0.0.5";
    format = "setuptools";

    src = fetchPypi {
      pname = "controlnet_aux";
      inherit version;
      hash = "sha256-xtwtVN/afiTblqocThBq7cVj3BQqNHtfOOzS8TuxBOk=";
    };

    propagatedBuildInputs = [
      einops
      filelock
      huggingface-hub
      importlib-metadata
      numpy
      opencv4
      pillow
      scikit-image
      scipy
      timm
      torch
      torchvision
    ];

    postPatch = ''
      sed -i -E \
        -e '/opencv-python/d' \
        ./setup.py
    '';

    pythonImportsCheck = [ "controlnet_aux" ];

    meta = with lib; {
      description = "Auxillary models for controlnet";
      homepage = "https://github.com/patrickvonplaten/controlnet_aux";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  lama-cleaner =
    let
      name = "lama-cleaner";
      version = "1.2.0";
    in
    buildPythonPackage {
      inherit version;
      pname = name;
      format = "setuptools";

      src = pkgs.fetchFromGitHub {
        owner = "Sanster";
        repo = name;
        rev = "870376e4bf5ea3fc25bda6164e38acd1d1c1ef4c";
        # rev = "refs/tags/${version}";
        hash = "sha256-ZX/Rbp+K6FI4OH/IkRsliIr5ALZcRb1LfMUmhuyDvt8=";
      };

      propagatedBuildInputs = [
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
          -e 's#(Jinja2)==(2.11.3)#\1>=\2#g' \
          -e 's#(flask)==(1.1.4)#\1>=\2#g' \
          -e 's#(flaskwebgui)==(0.3.5)#\1>=\2#g' \
          -e 's#(markupsafe)==(2.0.1)#\1>=\2#g' \
          -e 's#(transformers)==(4.27.4)#\1>=\2#g' \
          -e 's#(controlnet-aux)==(0.0.3)#\1>=\2#g' \
          ./requirements.txt
      '';

      pythonImportsCheck = [ "lama_cleaner" ];
      doCheck = false;

      meta = with lib; {
        description = "Image inpainting tool powered by SOTA AI Model";
        homepage = "https://github.com/Sanster/lama-cleaner";
        mainProgram = "lama-cleaner";
        license = licenses.asl20;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };
}
