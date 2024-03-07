final: prev:
let
  inherit (prev) buildPythonPackage fetchPypi;
  inherit (prev.lib) licenses maintainers;
in
{
  argilla = buildPythonPackage rec {
    pname = "argilla";
    version = "1.13.3";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-NXv8UGbPN/ExCwW6q3pvb0ntAowxLnnJGuSIVpu2Y34=";
    };

    nativeBuildInputs = with prev; [
      setuptools
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = [
      "numpy"
      "typer"
    ];

    propagatedBuildInputs = with prev; [
      backoff
      deprecated
      httpx
      monotonic
      numpy
      packaging
      pandas
      pydantic
      rich
      tqdm
      typer
      wrapt
    ];

    passthru.optional-dependencies = with prev; {
      integrations = [
        cleanlab
        datasets
        evaluate
        faiss-cpu
        flair
        flyingsquid
        huggingface-hub
        openai
        peft
        pgmpy
        plotly
        pyyaml
        seqeval
        setfit
        snorkel
        spacy
        spacy-transformers
        span-marker
        transformers
      ];
      listeners = [
        prodict
        schedule
      ];
      postgresql = [
        asyncpg
        psycopg2
        psycopg2-binary
      ];
      server = [
        aiofiles
        aiosqlite
        alembic
        brotli-asgi
        elasticsearch8
        fastapi
        greenlet
        luqum
        opensearch-py
        passlib
        psutil
        python-jose
        python-multipart
        pyyaml
        scikit-learn
        segment-analytics-python
        smart-open
        sqlalchemy
        uvicorn
      ];
      tests = [
        factory-boy
        pytest
        pytest-asyncio
        pytest-cov
        pytest-mock
      ];
    };

    pythonImportsCheck = [ "argilla" ];

    meta = {
      description = "Open-source tool for exploring, labeling, and monitoring data for NLP projects";
      homepage = "https://github.com/argilla-io/argilla";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

}
