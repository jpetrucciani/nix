final: prev:
let
  inherit (final) buildPythonPackage fetchPypi pythonRelaxDepsHook poetry-core;
  inherit (final.lib) licenses maintainers;
  inherit (final.pkgs) fetchFromGitHub;
in
rec {
  llama-index-core = buildPythonPackage rec {
    pname = "llama-index-core";
    version = "0.10.3";
    pyproject = true;

    src = fetchPypi {
      pname = "llama_index_core";
      inherit version;
      hash = "sha256-XM7SxWvWQDEYNQlP5pRs5kmObTHf/Ns991g/8ao4Ybg=";
    };

    nativeBuildInputs = [
      poetry-core
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = [ "nest-asyncio" ];

    propagatedBuildInputs = with final; [
      aiohttp
      dataclasses-json
      deprecated
      dirtyjson
      fsspec
      httpx
      nest-asyncio
      networkx
      nltk
      numpy
      openai
      pandas
      pillow
      pyyaml
      requests
      sqlalchemy
      tenacity
      tiktoken
      tqdm
      typing-extensions
      typing-inspect
    ];

    pythonImportsCheck = [ "llama_index.core" ];

    meta = {
      description = "Interface between LLMs and your data";
      homepage = "https://github.com/run-llama/llama_index";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  llama-index-readers-file = buildPythonPackage rec {
    pname = "llama-index-readers-file";
    version = "0.1.3";
    pyproject = true;

    src = fetchPypi {
      pname = "llama_index_readers_file";
      inherit version;
      hash = "sha256-IeLPTOogIVmitTdROPpSJX8nb4vISQwX3+Vyi0j2tv8=";
    };

    postPatch = ''
      sed -i -E '/bs4 /d' pyproject.toml
    '';

    nativeBuildInputs = [
      poetry-core
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = [
      "bs4"
      "beautifulsoup4"
      "pymupdf"
      "pypdf"
    ];

    propagatedBuildInputs = with final; [
      beautifulsoup4
      llama-index-core
      pymupdf
      pypdf
    ];

    pythonImportsCheck = [ "llama_index.readers.file" ];

    meta = {
      description = "Llama-index readers file integration";
      homepage = "https://pypi.org/project/llama-index-readers-file";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  llama-index-llms-openai = buildPythonPackage rec {
    pname = "llama-index-llms-openai";
    version = "0.1.1";
    pyproject = true;

    src = fetchPypi {
      pname = "llama_index_llms_openai";
      inherit version;
      hash = "sha256-8iQZYxQ3FSGUGENtjPEEoudfIiu0yCmBpDB5QrTlk0s=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      llama-index-core
    ];

    pythonImportsCheck = [ "llama_index.llms.openai" ];

    meta = {
      description = "Llama-index llms openai integration";
      homepage = "https://pypi.org/project/llama-index-llms-openai";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  llama-index-llms-vllm = buildPythonPackage rec {
    pname = "llama-index-llms-vllm";
    version = "0.1.1";
    pyproject = true;

    src = fetchPypi {
      pname = "llama_index_llms_vllm";
      inherit version;
      hash = "sha256-Y59OylxOvxh+rqvwsMV7UecIdCVgXtjwCh+xHswZ2KI=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      llama-index-core
    ];

    pythonImportsCheck = [ "llama_index.llms.vllm" ];

    meta = {
      description = "Llama-index llms vllm integration";
      homepage = "https://pypi.org/project/llama-index-llms-vllm";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  llama-index-llms-anyscale = buildPythonPackage rec {
    pname = "llama-index-llms-anyscale";
    version = "0.1.1";
    pyproject = true;

    src = fetchPypi {
      pname = "llama_index_llms_anyscale";
      inherit version;
      hash = "sha256-X5OB8RwDujwWobBwaVM1fpQR8CyWIrFIXiuCw0VuyfA=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      llama-index-core
      llama-index-llms-openai
    ];

    pythonImportsCheck = [ "llama_index.llms.anyscale" ];

    meta = {
      description = "Llama-index llms anyscale integration";
      homepage = "https://pypi.org/project/llama-index-llms-anyscale";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  llama-index-llms-mistralai = buildPythonPackage rec {
    pname = "llama-index-llms-mistralai";
    version = "0.1.1";
    pyproject = true;

    src = fetchPypi {
      pname = "llama_index_llms_mistralai";
      inherit version;
      hash = "sha256-JrSC+uR7tnP33aswa1BBTDs8igDWdrUx1CkxgohrWbE=";
    };

    nativeBuildInputs = [
      poetry-core
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = [ "mistralai" ];
    propagatedBuildInputs = with final; [
      llama-index-core
      mistralai
    ];

    pythonImportsCheck = [ "llama_index.llms.mistralai" ];

    meta = {
      description = "Llama-index llms mistral ai integration";
      homepage = "https://pypi.org/project/llama-index-llms-mistralai";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  llama-index-llms-llama-cpp = buildPythonPackage rec {
    pname = "llama-index-llms-llama-cpp";
    version = "0.1.1";
    pyproject = true;

    src = fetchPypi {
      pname = "llama_index_llms_llama_cpp";
      inherit version;
      hash = "sha256-gRFUZmLX6QjO9KaciohS0cyqtrcWY9TQeMz6B9fjTeQ=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = with final; [
      llama-cpp-python
      llama-index-core
    ];

    pythonImportsCheck = [ "llama_index.llms.llama_cpp" ];

    meta = {
      description = "Llama-index llms llama cpp integration";
      homepage = "https://pypi.org/project/llama-index-llms-llama-cpp";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  llama-index-legacy = buildPythonPackage rec {
    pname = "llama-index-legacy";
    version = "0.10.3";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "run-llama";
      repo = "llama_index";
      rev = "refs/tags/v${version}";
      hash = "sha256-aoa2Obzcc6/rzQ7v3Yck9e5m36nIMwOItCo+Vwd27/U=";
    };
    sourceRoot = "source/llama-index-legacy";

    nativeBuildInputs = [
      pythonRelaxDepsHook
      poetry-core
    ];

    nativeCheckInputs = with final; [
      pytestCheckHook
      nltk
      pillow
    ];

    pythonRelaxDeps = [
      "fsspec"
      "langchain"
      "nest-asyncio"
      "sqlalchemy"
    ];

    propagatedBuildInputs = with final; [
      beautifulsoup4
      deprecated
      dirtyjson
      faiss
      fsspec
      langchain
      nest-asyncio
      networkx
      nltk
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

    pythonImportsCheck = [ "llama_index" ];
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

    nativeBuildInputs = with final; [
      poetry-core
    ];

    propagatedBuildInputs = with final; [
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

  llama-index-agent-openai = buildPythonPackage rec {
    pname = "llama-index-agent-openai";
    version = "0.1.1";
    pyproject = true;

    src = fetchPypi {
      pname = "llama_index_agent_openai";
      inherit version;
      hash = "sha256-hq6VwTyfhRReGFxZfOLlvT6WZ83XCVK8/epE0HL0uZo=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      llama-index-core
      llama-index-llms-openai
    ];

    pythonImportsCheck = [ "llama_index.agent.openai" ];

    meta = {
      description = "Llama-index agent openai integration";
      homepage = "https://pypi.org/project/llama-index-agent-openai";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  llama-index-embeddings-openai = buildPythonPackage rec {
    pname = "llama-index-embeddings-openai";
    version = "0.1.1";
    pyproject = true;

    src = fetchPypi {
      pname = "llama_index_embeddings_openai";
      inherit version;
      hash = "sha256-uT0pbLh7KUXWDJ5XDis2dxFROiOYmdKYfLFeEcRHxAo=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      llama-index-core
    ];

    pythonImportsCheck = [ "llama_index.embeddings.openai" ];

    meta = {
      description = "Llama-index embeddings openai integration";
      homepage = "https://pypi.org/project/llama-index-embeddings-openai";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  llama-index-embeddings-huggingface = buildPythonPackage rec {
    pname = "llama-index-embeddings-huggingface";
    version = "0.1.1";
    pyproject = true;

    src = fetchPypi {
      pname = "llama_index_embeddings_huggingface";
      inherit version;
      hash = "sha256-hSeLPgE+1iDXVpEVTbicYynfIU389tyiGU8E0cOX1p0=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = with final; [
      huggingface-hub
      llama-index-core
      torch
      transformers
    ];

    pythonImportsCheck = [ "llama_index.embeddings.huggingface" ];

    meta = {
      description = "Llama-index embeddings huggingface integration";
      homepage = "https://pypi.org/project/llama-index-embeddings-huggingface";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  llama-index-program-openai = buildPythonPackage rec {
    pname = "llama-index-program-openai";
    version = "0.1.1";
    pyproject = true;

    src = fetchPypi {
      pname = "llama_index_program_openai";
      inherit version;
      hash = "sha256-EMsCrD5Cl622AggUtC8D+X583wTm47s3MWUgFepWwh0=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      llama-index-core
      llama-index-agent-openai
      llama-index-llms-openai
    ];

    pythonImportsCheck = [ "llama_index.program.openai" ];

    meta = {
      description = "Llama-index program openai integration";
      homepage = "https://pypi.org/project/llama-index-program-openai";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  llama-index-question-gen-openai = buildPythonPackage rec {
    pname = "llama-index-question-gen-openai";
    version = "0.1.1";
    pyproject = true;

    src = fetchPypi {
      pname = "llama_index_question_gen_openai";
      inherit version;
      hash = "sha256-1zB0o0lcictlBdT5V9XCh4zjMnx2Nid/bEpDTv8PP8Y=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      llama-index-core
      llama-index-llms-openai
      llama-index-program-openai
    ];

    pythonImportsCheck = [ "llama_index.question_gen.openai" ];

    meta = {
      description = "Llama-index question_gen openai integration";
      homepage = "https://pypi.org/project/llama-index-question-gen-openai";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  llama-index-multi-modal-llms-openai = buildPythonPackage rec {
    pname = "llama-index-multi-modal-llms-openai";
    version = "0.1.1";
    pyproject = true;

    src = fetchPypi {
      pname = "llama_index_multi_modal_llms_openai";
      inherit version;
      hash = "sha256-oGsDPj1oYbcVHgw56lX0U2aZYBTo3puRWjp7QPxrDPU=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      llama-index-core
      llama-index-llms-openai
    ];

    pythonImportsCheck = [ "llama_index.multi_modal_llms.openai" ];

    meta = {
      description = "Llama-index multi-modal-llms openai integration";
      homepage = "https://pypi.org/project/llama-index-multi-modal-llms-openai";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  llama-index = buildPythonPackage rec {
    pname = "llama-index";
    version = "0.10.3";
    pyproject = true;

    src = fetchPypi {
      pname = "llama_index";
      inherit version;
      hash = "sha256-4qHbcZx2FLxEwPWTpz4P0NBJHzDoqf6kqZhTulPBut0=";
    };

    nativeBuildInputs = with final; [
      poetry-core
    ];

    propagatedBuildInputs = [
      llama-index-agent-openai
      llama-index-core
      llama-index-embeddings-openai
      llama-index-legacy
      llama-index-llms-openai
      llama-index-multi-modal-llms-openai
      llama-index-program-openai
      llama-index-question-gen-openai
      llama-index-readers-file
    ];

    pythonImportsCheck = [ "llama_index" ];

    meta = {
      description = "Interface between LLMs and your data";
      homepage = "https://pypi.org/project/llama-index";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
