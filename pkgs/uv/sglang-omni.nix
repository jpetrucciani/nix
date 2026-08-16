# [SGLang-Omni](https://github.com/sgl-project/sglang-omni) is a multi-stage serving runtime for omni, speech, and TTS models.
{ sglang-omni
, lib
, uv-nix
, bash
, cudatoolkit
, clang
, ninja
, sox
, python312
, version ? "unstable-2026-08-15-2d2ff50"
, rev ? "2d2ff5056f8c321f1dbc2ff6584baf05996ce150"
, lockHash ? "sha256-615SIRLYRxCxoNROMyXD2ee0yTxuvFZrUKJrF+2vf7o="
, isWSL ? false
, includePin ? false
}:
let
  ldPath = if isWSL then "/usr/lib/wsl/lib" else "/run/opengl-driver/lib";
in
uv-nix.buildUvPackage rec {
  inherit version includePin;
  pname = "sglang-omni";
  bins = [
    "sgl-omni"
    "sgl-omni-router"
  ];
  python = python312;

  lockUrl = "https://static.g7c.us/lock/uv/sglang-omni/${version}.lock";
  inherit lockHash;
  extraDependencies = [
    "qwen-tts==0.1.1"
    "sox"
    "einops"
    "onnxruntime"
  ];
  pyprojectOverrides = _final: _prev: {
    "sglang-omni" = _prev."sglang-omni".overrideAttrs (old: {
      # Music3 stores its acoustic checkpoint as FP32. Loading it directly on
      # the GPU defeats the BF16 runtime override and adds a 9 GiB startup
      # spike, so stage it in host RAM and transfer tensors at their final
      # inference dtype.
      postInstall = (old.postInstall or "") + ''
        patch \
          --fuzz=0 \
          -d "$out/${python312.sitePackages}" \
          -p1 \
          < ${./patches/sglang-omni-minimax-music3-bf16-load.patch}
      '';
    });
    "nixl-cu13" = _prev."nixl-cu13".overrideAttrs (old: {
      # The CUDA-specific wheel omits the `nixl` meta-package namespace that
      # SGLang-Omni imports. This package is CUDA 13-only, so expose its backend
      # under the expected name without pulling in the unused CUDA 12 wheel.
      postInstall = (old.postInstall or "") + ''
        ln -s nixl_cu13 "$out/${python312.sitePackages}/nixl"
      '';
    });
    "qwen-tts" = _prev."qwen-tts".overrideAttrs (old: {
      # SGLang-Omni deliberately keeps Transformers 5.12 while installing
      # qwen-tts without its Transformers 4.57 dependency. Patch the wheel
      # after installation because uv2nix cannot patch wheel sources earlier.
      postInstall = (old.postInstall or "") + ''
        patch \
          --fuzz=0 \
          -d "$out/${python312.sitePackages}" \
          -p1 \
          < ${./patches/qwen-tts-transformers-5.patch}
      '';
    });
  };
  cudaSupport = true;

  postInstall = ''
    sitePackages=$(echo "$out"/lib/python*/site-packages)
    wheelCudaLibs="$sitePackages/torch/lib"
    for libdir in "$sitePackages"/nvidia/*/lib; do
      wheelCudaLibs="$wheelCudaLibs:$libdir"
    done
    for program in sgl-omni sgl-omni-router; do
      wrapProgram "$out/bin/$program" \
        --set LD_LIBRARY_PATH "$wheelCudaLibs:${ldPath}" \
        --set CUDA_HOME "${cudatoolkit}" \
        --set CUDA_PATH "${cudatoolkit}" \
        --prefix CPATH : "${cudatoolkit}/include" \
        --prefix CPLUS_INCLUDE_PATH : "${cudatoolkit}/include" \
        --prefix LIBRARY_PATH : "${cudatoolkit}/lib" \
        --prefix LIBRARY_PATH : "${ldPath}" \
        --set TRITON_LIBCUDA_PATH "${ldPath}" \
        --set TRITON_PTXAS_PATH "${cudatoolkit}/bin/ptxas" \
        --set UCX_MODULE_DIR "$sitePackages/nixl_cu13.libs/ucx" \
        --prefix PATH : ${lib.makeBinPath [
          bash
          cudatoolkit
          clang
          ninja
          sox
        ]}
    done
  '';

  passthru = {
    inherit rev;
    wsl = sglang-omni.override {
      inherit version rev lockHash includePin;
      isWSL = true;
    };
  };

  meta = {
    changelog = "https://github.com/sgl-project/sglang-omni/commit/${rev}";
    description = "a multi-stage serving runtime for omni, speech, and TTS models";
    homepage = "https://github.com/sgl-project/sglang-omni";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "sgl-omni";
    platforms = lib.platforms.linux;
    skipBuild = true; # don't ever build this on github actions - it's quite heavy!
  };
}
