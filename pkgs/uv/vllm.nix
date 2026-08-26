# [vllm](https://github.com/vllm-project/vllm) is a high-throughput and memory-efficient inference and serving engine for LLMs
{ vllm
, lib
, uv-nix
, cudatoolkit
, clang
, ninja
, mkVllmRefresh
, version ? "0.28.0"
, lockHash ? "sha256-E2WSIUSwk7uBi2Xi9wFzqkLmdo015nb7oDd4aP2n5mY="
, isWSL ? false
, includePin ? false
}:
let
  ldPath = if isWSL then "/usr/lib/wsl/lib" else "/run/opengl-driver/lib";
  extraDependencies = [
    "flashinfer-python>=0.6.12"
    "openai>=2.25.0"
    "transformers>=5.12.0"
    "qwen-vl-utils==0.0.14"
  ];
in
uv-nix.buildUvPackage rec {
  inherit version lockHash includePin;
  pname = "vllm";

  lockUrl = "https://static.g7c.us/lock/uv/vllm/${version}.lock";
  inherit extraDependencies;
  cudaSupport = true;

  postInstall = ''
    sitePackages=$(echo "$out"/lib/python*/site-packages)
    wheelCudaLibs="$sitePackages/torch/lib"
    for libdir in "$sitePackages"/nvidia/*/lib; do
      wheelCudaLibs="$wheelCudaLibs:$libdir"
    done
    wrapProgram $out/bin/vllm \
      --set LD_LIBRARY_PATH "$wheelCudaLibs:${ldPath}" \
      --set CUDA_HOME "${cudatoolkit}" \
      --set CUDA_PATH "${cudatoolkit}" \
      --prefix CPATH : "${cudatoolkit}/include" \
      --prefix CPLUS_INCLUDE_PATH : "${cudatoolkit}/include" \
      --prefix LIBRARY_PATH : "${cudatoolkit}/lib" \
      --set TRITON_LIBCUDA_PATH "${ldPath}" \
      --set TRITON_PTXAS_PATH "${cudatoolkit}/bin/ptxas" \
      --prefix PATH : ${
        lib.makeBinPath [
          cudatoolkit
          clang
          ninja
        ]
      }
  '';

  passthru = {
    inherit lockHash lockUrl;
    updateScript = mkVllmRefresh { inherit extraDependencies; };
    wsl = vllm.override { isWSL = true; };
  };

  meta = {
    changelog = "https://github.com/vllm-project/vllm/releases/tag/v${version}";
    description = "a high-throughput and memory-efficient inference and serving engine for LLMs";
    homepage = "https://github.com/vllm-project/vllm";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "vllm";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    skipBuild = true; # don't ever build this on github actions - it's quite heavy!
  };
}
