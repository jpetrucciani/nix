# [vllm](https://github.com/vllm-project/vllm) is a high-throughput and memory-efficient inference and serving engine for LLMs
{ vllm, lib, uv-nix, cudatoolkit, clang, version ? "0.12.0", lockHash ? "sha256-k3k8avl9cSro/0B9KYWNm4/rwEmEjUJPrbIuqggj5yU=", isWSL ? false, includePin ? false }:
let
  ldPath = if isWSL then "/usr/lib/wsl/lib" else "/run/opengl-driver/lib";
in
uv-nix.buildUvPackage rec {
  inherit version lockHash includePin;
  pname = "vllm";

  lockUrl = "https://static.g7c.us/lock/uv/vllm/${version}.lock";
  extraDependencies = [ "flashinfer-python==0.3.1.post1" "qwen-vl-utils==0.0.14" ];
  cudaSupport = true;

  postInstall = ''
    wrapProgram $out/bin/vllm \
      --set LD_LIBRARY_PATH "${ldPath}" \
      --set TRITON_LIBCUDA_PATH "${ldPath}" \
      --set TRITON_PTXAS_PATH "${cudatoolkit}/bin/ptxas" \
      --prefix PATH : ${clang}/bin
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
