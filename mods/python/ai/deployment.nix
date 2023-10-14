final: prev:
let
  inherit (prev) buildPythonPackage fetchPypi;
  inherit (prev.lib) licenses maintainers;
in
{
  vllm-client = buildPythonPackage rec {
    pname = "vllm-client";
    version = "0.1.7";
    pyproject = true;

    src = fetchPypi {
      pname = "vllm_client";
      inherit version;
      hash = "sha256-bGPevAT/DJiDLUOJLuRnlPAi462uCxWocLWQaDwNUZQ=";
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
      homepage = "https://pypi.org/project/vllm-client/";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
