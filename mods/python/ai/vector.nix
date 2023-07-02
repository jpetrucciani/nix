final: prev: with prev; let
  inherit (stdenv) isAarch64 isDarwin;
  inherit (prev.pkgs) darwin;
  isM1 = isDarwin && isAarch64;
in
{
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
}
