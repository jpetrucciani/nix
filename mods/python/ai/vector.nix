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
      version = "0.4.22";
      format = "pyproject";

      src = fetchPypi {
        inherit pname version;
        hash = "sha256-x5MUnhwru7Utd2AsbAWUxXUvBM2b4SYZJQ3a0ggq8no=";
      };

      nativeBuildInputs = with prev; [
        pythonRelaxDepsHook
        setuptools
        setuptools-scm
      ];

      pythonRelaxDeps = [
        "fastapi"
        "onnxruntime"
        "tqdm"
      ];

      propagatedBuildInputs = with prev; [
        bcrypt
        chroma-hnswlib
        clickhouse-connect
        duckdb
        fastapi
        httptools
        importlib-resources
        numpy
        overrides
        opentelemetry-api
        opentelemetry-exporter-otlp-proto-common
        opentelemetry-exporter-otlp-proto-grpc
        opentelemetry-sdk
        pandas
        posthog
        pulsar-client
        pydantic
        pypika
        python-dotenv
        requests
        tenacity
        tokenizers
        tqdm
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
