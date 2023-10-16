final: prev:
let
  inherit (prev) buildPythonPackage;
  inherit (prev.lib) licenses maintainers;
  inherit (prev.pkgs) fetchFromGitHub;
in
{
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
