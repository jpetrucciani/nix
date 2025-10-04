# [vllm](https://github.com/vllm-project/vllm) is a high-throughput and memory-efficient inference and serving engine for LLMs
{ vllm, lib, uv-nix, cudatoolkit, isWSL ? false }:
let
  ldPath = if isWSL then "/usr/lib/wsl/lib" else "/run/opengl-driver/lib";
in
uv-nix.buildUvPackage rec {
  pname = "vllm";
  version = "0.11.0";

  lockUrl = "https://static.g7c.us/lock/uv/vllm/${version}.lock";
  lockHash = "sha256-z7va7PqfO1kbAHihtmIG5WppHNuSRi32MzuVR7OJSk4=";
  extraDependencies = [ "flashinfer-python==0.3.1.post1" "qwen-vl-utils==0.0.14" ];
  cudaSupport = true;

  postInstall = ''
    wrapProgram $out/bin/vllm \
      --set LD_LIBRARY_PATH "${ldPath}" \
      --set TRITON_LIBCUDA_PATH "${ldPath}" \
      --set TRITON_PTXAS_PATH "${cudatoolkit}/bin/ptxas"
  '';

  passthru = {
    wsl = vllm.override { isWSL = true; };
  };

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
