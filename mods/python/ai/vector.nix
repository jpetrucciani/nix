final: prev:
let
  inherit (prev) buildPythonPackage fetchPypi;
  inherit (prev.lib) licenses maintainers;
in
{
  chromadb =
    let
      inherit (prev.pkgs.stdenv) isDarwin;
    in
    buildPythonPackage rec {
      pname = "chromadb";
      version = "0.5.11";
      pyproject = true;

      src = fetchPypi {
        inherit pname version;
        hash = "sha256-JS6XCz4aJ7WUzHs2hSOGkb+OqiMiJdTe6eM+yDWAd18=";
      };

      nativeBuildInputs = with prev; [
        pythonRelaxDepsHook
        setuptools
        setuptools-scm
      ];

      pythonRelaxDeps = [
        "fastapi"
        "onnxruntime"
        "orjson"
        "tqdm"
      ];

      propagatedBuildInputs = with final; [
        bcrypt
        build
        chroma-hnswlib
        clickhouse-connect
        duckdb
        fastapi
        httptools
        httpx
        importlib-resources
        kubernetes
        mmh3
        numpy
        opentelemetry-api
        opentelemetry-exporter-otlp-proto-common
        opentelemetry-exporter-otlp-proto-grpc
        opentelemetry-instrumentation-fastapi
        opentelemetry-sdk
        orjson
        overrides
        pandas
        posthog
        pulsar-client
        pydantic
        pypika
        python-dotenv
        pyyaml
        requests
        tenacity
        tokenizers
        tqdm
        typer
        typing-extensions
        uvicorn
        uvloop
        watchfiles
        websockets
      ] ++ (if !isDarwin then [ onnxruntime ] else [ ]);

      postPatch =
        let
          onnx_patch = if isDarwin then "sed -i -E  '/onnxruntime/d' ./pyproject.toml" else "";
        in
        ''
          ${onnx_patch}
        '';

      pythonImportsCheck = [ "chromadb" ];

      meta = {
        description = "the AI-native open-source embedding database ";
        homepage = "https://github.com/chroma-core/chroma";
        license = licenses.asl20;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };
}
