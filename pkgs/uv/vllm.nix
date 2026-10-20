# [vllm](https://github.com/vllm-project/vllm) is a high-throughput and memory-efficient inference and serving engine for LLMs
{ vllm
, lib
, uv-nix
, cudatoolkit
, cudaPackages
, clang
, ninja
, mkVllmRefresh
, version ? "0.32.0"
, lockHash ? "sha256-uogCHL7EbAKeOeRReVc/cZWukW1DiBw+f+oa0XFqW3s="
, isWSL ? false
, includePin ? false
}:
let
  ldPath = if isWSL then "/usr/lib/wsl/lib" else "/run/opengl-driver/lib";
  # JIT compilation uses the toolchain and libraries. Omit debugging tools,
  # whose executables fail during patchelf's driver-runpath fixup.
  cudaToolkit = cudatoolkit.overrideAttrs (old: {
    paths = lib.subtractLists
      (lib.concatMap
        (pkg: map (output: toString pkg.${output}) pkg.outputs)
        (with cudaPackages; [ cuda_gdb cuda_sanitizer_api ]))
      old.paths;
  });
  extraDependencies = [
    "flashinfer-python>=0.6.12"
    "openai>=2.25.0"
    "transformers>=5.12.0"
    "qwen-vl-utils==0.0.14"
  ];
  refreshScript = mkVllmRefresh { inherit extraDependencies; };
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
      --set CUDA_HOME "${cudaToolkit}" \
      --set CUDA_PATH "${cudaToolkit}" \
      --prefix CPATH : "${cudaToolkit}/include" \
      --prefix CPLUS_INCLUDE_PATH : "${cudaToolkit}/include" \
      --prefix LIBRARY_PATH : "${cudaToolkit}/lib" \
      --set TRITON_LIBCUDA_PATH "${ldPath}" \
      --set TRITON_PTXAS_PATH "${cudaToolkit}/bin/ptxas" \
      --prefix PATH : ${
        lib.makeBinPath [
          cudaToolkit
          clang
          ninja
        ]
      }
  '';

  passthru = {
    inherit lockHash lockUrl refreshScript;
    updateScript = lib.getExe refreshScript;
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
