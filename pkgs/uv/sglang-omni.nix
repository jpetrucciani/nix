# [SGLang-Omni](https://github.com/sgl-project/sglang-omni) is a multi-stage serving runtime for omni, speech, and TTS models.
{ sglang-omni
, lib
, uv-nix
, cudatoolkit
, clang
, ninja
, sox
, python312
, version ? "unstable-2026-08-03-c33d5c1"
, rev ? "c33d5c1440d67252cf9b5f8a8645b82a83eb039e"
, lockHash ? "sha256-DRkDfTHgxOhQoGG15EHweQXMVpfdCJCNe01ud5uXZCI="
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
