final: prev:
let
  inherit (prev) buildPythonPackage;
  inherit (prev.lib) licenses maintainers;
  inherit (prev.pkgs) fetchFromGitHub;
in
{
  fastembed = buildPythonPackage rec {
    pname = "fastembed";
    version = "0.1.1";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "qdrant";
      repo = pname;
      rev = "refs/tags/v${version}";
      hash = "sha256-6bLINktZLJWWdno0wJVh/IdubiLH8Ge6Km8LwfHCIg4=";
    };

    nativeBuildInputs = with prev; [
      poetry-core
    ];

    propagatedBuildInputs = with prev; [
      onnx
      onnxruntime
      requests
      tokenizers
      tqdm
    ];

    pythonImportsCheck = [ "fastembed" ];

    meta = {
      description = "Fast, light, accurate library built for retrieval embedding generation";
      homepage = "https://github.com/qdrant/fastembed";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  vllm-client = buildPythonPackage rec {
    pname = "vllm-client";
    version = "0.2.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "viktor-ferenczi";
      repo = pname;
      rev = "refs/tags/${version}";
      hash = "sha256-JUoGM0lR1lWTurfREI5fdJl7KGaXePQ9OXBWXcIb1ZE=";
    };

    nativeBuildInputs = with prev; [
      aiohttp
      packaging
      setuptools
      wheel
    ];

    propagatedBuildInputs = with prev; [
      aiohttp
    ];

    pythonImportsCheck = [ "vllm_client" ];

    meta = {
      description = "Client for the vLLM API with minimal dependencies";
      homepage = "https://github.com/viktor-ferenczi/vllm-client";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
