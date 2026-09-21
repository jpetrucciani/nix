# [vLLM-Omni](https://github.com/vllm-project/vllm-omni) serves omni-modality and diffusion models with vLLM.
{ vllm-omni
, lib
, uv-nix
, bash
, cudatoolkit
, clang
, fetchurl
, ninja
, python313
, lockHash ? "sha256-u9/VUuBZEYhiqS0YaNT/Vi3KH4r3vLUb8HVMQ27eHB0="
, isWSL ? false
}:
let
  baseVersion = "0.29.0rc1";
  version = "${baseVersion}-qwen-image-2.1";
  qwenImageRev = "3d6a1c4d9a0a09d8392bda3a54f8dfb890d5fb05";
  qwenImageSource = fetchurl {
    url = "https://github.com/vllm-project/vllm-omni/archive/${qwenImageRev}.tar.gz";
    hash = "sha256-KOTTqFks8AZrvjGRnGq8jpdfl3Ji6ye0nad2hD2CKSA=";
  };
  lockUrl = "https://static.g7c.us/lock/uv/vllm-omni/${baseVersion}.lock";
  ldPath = if isWSL then "/usr/lib/wsl/lib" else "/run/opengl-driver/lib";
  bins = [
    "vllm"
    "vllm-omni"
  ];
in
uv-nix.buildUvPackage {
  inherit version lockHash lockUrl bins;
  pname = "vllm-omni";
  python = python313;
  includePin = false;

  # vLLM-Omni intentionally does not declare vLLM as a package dependency.
  # The Qwen-Image 2.1 branch added scipy and s3tokenizer after 0.29.0rc1.
  extraDependencies = [
    "vllm==0.29.0"
    "scipy>=1.11.0"
    "s3tokenizer==0.3.0"
  ];
  cudaSupport = true;

  postInstall = ''
    sitePackages=$(echo "$out"/lib/python*/site-packages)

    # The 0.29.0rc1 wheel predates Qwen-Image 2.1. Keep its dependency and
    # entry-point metadata, but install the exact upstream implementation under
    # review in https://github.com/vllm-project/vllm-omni/pull/7759.
    sourceRoot="$TMPDIR/vllm-omni-source"
    versionModule="$TMPDIR/vllm-omni-version.py"
    mkdir -p "$sourceRoot"
    tar -xzf ${qwenImageSource} --strip-components=1 -C "$sourceRoot"
    cp "$sitePackages/vllm_omni/_version.py" "$versionModule"
    chmod u+w "$sitePackages"
    rm "$sitePackages/vllm_omni"
    cp -r "$sourceRoot/vllm_omni" "$sitePackages/vllm_omni"
    install -m 0644 "$versionModule" "$sitePackages/vllm_omni/_version.py"

    wheelCudaLibs="$sitePackages/torch/lib"
    for libdir in "$sitePackages"/nvidia/*/lib; do
      wheelCudaLibs="$wheelCudaLibs:$libdir"
    done
    for program in ${lib.escapeShellArgs bins}; do
      wrapProgram "$out/bin/$program" \
        --set PYTHONNOUSERSITE 1 \
        --set LD_LIBRARY_PATH "$wheelCudaLibs:${ldPath}" \
        --set CUDA_HOME "${cudatoolkit}" \
        --set CUDA_PATH "${cudatoolkit}" \
        --prefix CPATH : "${cudatoolkit}/include" \
        --prefix CPLUS_INCLUDE_PATH : "${cudatoolkit}/include" \
        --prefix LIBRARY_PATH : "${cudatoolkit}/lib" \
        --prefix LIBRARY_PATH : "${ldPath}" \
        --set TRITON_LIBCUDA_PATH "${ldPath}" \
        --set TRITON_PTXAS_PATH "${cudatoolkit}/bin/ptxas" \
        --prefix PATH : "${lib.makeBinPath [
          bash
          cudatoolkit
          clang
          ninja
        ]}"
    done
  '';

  passthru = {
    inherit baseVersion lockHash lockUrl qwenImageRev qwenImageSource;
    wsl = vllm-omni.override { isWSL = true; };
  };

  meta = {
    changelog = "https://github.com/vllm-project/vllm-omni/pull/7759";
    description = "Framework for efficient omni-modality model inference with vLLM";
    homepage = "https://github.com/vllm-project/vllm-omni";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "vllm";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    skipBuild = true; # don't ever build this on github actions - it's quite heavy!
  };
}
