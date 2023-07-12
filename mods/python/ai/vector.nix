final: prev: with prev; {
  chromadb =
    let
      inherit (stdenv) isDarwin;
    in
    buildPythonPackage rec {
      pname = "chromadb";
      version = "0.3.29";
      format = "pyproject";

      src = fetchPypi {
        inherit pname version;
        hash = "sha256-KdR4NdpJT8G1jaQKuxQ1aJ1Lock99sZGZKXZFSHLgOk=";
      };

      nativeBuildInputs = [
        pythonRelaxDepsHook
        setuptools
        setuptools-scm
      ];

      pythonRelaxDeps = [
        "fastapi"
        "onnxruntime"
        "tqdm"
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
        pulsar-client
        pydantic
        python-dotenv
        requests
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

      meta = with lib; {
        description = "the AI-native open-source embedding database ";
        homepage = "https://github.com/chroma-core/chroma";
        license = licenses.asl20;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };
}
