final: prev: with prev; rec {
  llama-cpp-python =
    let
      osSpecific = with pkgs.darwin.apple_sdk.frameworks; if pkgs.stdenv.isDarwin then [ Accelerate ] else [ ];
      llama-cpp-pin = pkgs.fetchFromGitHub {
        owner = "ggerganov";
        repo = "llama.cpp";
        rev = "3e6e70d8e8917b5bd14c7c9f9b89a585f1ff0b31";
        hash = "sha256-jj7FV0I3fuMPWpNECxVHn4ZseJKPxUb/WpTmLW/CchI=";
      };
    in
    buildPythonPackage rec {
      pname = "llama-cpp-python";
      version = "0.1.32";

      format = "pyproject";
      src = pkgs.fetchFromGitHub {
        owner = "abetlen";
        repo = pname;
        rev = "bc02ce353b29cf67ff66a31eee6c14c5ceff708c";
        hash = "sha256-CFP39qnG+AkYWszFaNZnh2vMhOBMRgZ46at/OMFmUiI=";
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

  langchain = buildPythonPackage rec {
    pname = "langchain";
    version = "0.0.137";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-2Lf0VJDIadWXo36UP9hDf1QUsGMlPn4YpCKMUfsHW8U=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      pyyaml
      (sqlalchemy.overridePythonAttrs {
        version = "1.4.42";
        src = fetchPypi {
          version = "1.4.42";
          pname = "SQLAlchemy";
          hash = "sha256-F35BkUxHbtHht3/QWWbqiMCUBT4XqFMDxM4Af4jv82M=";
        };
      })
      aiohttp
      dataclasses-json
      numpy
      openapi-schema-pydantic
      pydantic
      pyowm
      requests
      tenacity
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

    meta = with lib; {
      description = "Building applications with LLMs through composability";
      homepage = "https://github.com/hwchase17/langchain";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  llama-index = buildPythonPackage rec {
    pname = "llama-index";
    version = "0.5.12";
    format = "setuptools";

    src = fetchPypi {
      pname = "llama_index";
      inherit version;
      hash = "sha256-AIPsAZRrfB8VbJkPGAwKZ64OPRFLPfCFGHIfSroyAPk=";
    };

    nativeCheckInputs = [
      ipython
      pillow
    ];

    propagatedBuildInputs = [
      langchain
      tiktoken
      numpy
      openai
      pandas
    ];

    pythonImportsCheck = [ "llama_index" ];

    meta = with lib; {
      description = "Interface between LLMs and your data";
      homepage = "https://github.com/jerryjliu/llama_index";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
