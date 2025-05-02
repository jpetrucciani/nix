# [vllm](https://github.com/vllm-project/vllm) is a high-throughput and memory-efficient inference and serving engine for LLMs
{ lib, uv-nix }:
uv-nix.buildUvPackage rec {
  pname = "vllm";
  version = "0.8.5";

  lockUrl = "https://static.g7c.us/lock/uv/vllm/${version}.lock";
  lockHash = "sha256-jzhEm0KRrS86iEb7xLHouRdA9AVVh3pPxi3Cxj0QzuQ=";
  extraDependencies = [ "flashinfer-python>=0.2.5" ];
  cudaSupport = true;

  meta = {
    changelog = "https://github.com/vllm-project/vllm/releases/tag/v${version}";
    description = "a high-throughput and memory-efficient inference and serving engine for LLMs";
    homepage = "https://github.com/vllm-project/vllm";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "vllm";
    skipBuild = true; # don't ever build this on github actions - it's quite heavy!
  };
}
