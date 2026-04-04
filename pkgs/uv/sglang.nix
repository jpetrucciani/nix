# [sglang](https://github.com/sgl-project/sglang) is a high-performance serving framework for large language models and multimodal models.
{ sglang, lib, uv-nix, cudatoolkit, clang, ninja, python313, fetchurl, stdenv, version ? "0.5.6-dflash", lockHash ? "sha256-58eN5oohBiNzhHiNZAOzmWyQqwBJeRKynfvJItspsrM=", isWSL ? false, includePin ? false }:
let
  ldPath = if isWSL then "/usr/lib/wsl/lib" else "/run/opengl-driver/lib";
  runtimePythonPath = lib.concatStringsSep ":" [
    "${python313.pkgs.imageio}/${python313.sitePackages}"
    "${python313.pkgs."imageio-ffmpeg"}/${python313.sitePackages}"
  ];
  cudnnWheel =
    {
      x86_64-linux = {
        url = "https://files.pythonhosted.org/packages/73/ad/bf4d7b6b097b53f0b36551466cbc196b84e27a0252d89d6a9d2afc5f7c5f/nvidia_cudnn_cu12-9.16.0.29-py3-none-manylinux_2_27_x86_64.whl";
        hash = "sha256-eNBbRDTazH3ZvJA9XDOi8opfAGTQJWjveyQY+J9sWSI=";
      };
      aarch64-linux = {
        url = "https://files.pythonhosted.org/packages/8a/f0/c3b578dd84d56eb0a45968afcafee93ed1c0b125d92394ce08be6c78c9ed/nvidia_cudnn_cu12-9.16.0.29-py3-none-manylinux_2_27_aarch64.whl";
        hash = "sha256-SwnEMJbbWC8RDFVy0Ly9mLMNcJ6GCo9zxsOEa6qDuNI=";
      };
    }.${stdenv.hostPlatform.system} or (throw "Unsupported system for sglang cudnn override: ${stdenv.hostPlatform.system}");
  packagePyprojectOverrides = final: prev: {
    nvidia-cudnn-cu12 = prev.nvidia-cudnn-cu12.overrideAttrs (_: {
      version = "9.16.0.29";
      src = fetchurl cudnnWheel;
    });
  };
in
uv-nix.buildUvPackage rec {
  inherit version lockHash includePin;
  pname = "sglang";

  lockUrl = "https://static.g7c.us/lock/uv/sglang/${version}.lock";
  extraDependencies = [ ];
  cudaSupport = true;
  pyprojectOverrides = packagePyprojectOverrides;

  postInstall = ''
    sitePackages=$(echo "$out"/lib/python*/site-packages)
    wheelCudaLibs="$sitePackages/torch/lib"
    for libdir in "$sitePackages"/nvidia/*/lib; do
      wheelCudaLibs="$wheelCudaLibs:$libdir"
    done
    wrapProgram $out/bin/sglang \
      --set LD_LIBRARY_PATH "$wheelCudaLibs:${ldPath}" \
      --prefix PYTHONPATH : "${runtimePythonPath}" \
      --set CUDA_HOME "${cudatoolkit}" \
      --set CUDA_PATH "${cudatoolkit}" \
      --prefix CPATH : "${cudatoolkit}/include" \
      --prefix CPLUS_INCLUDE_PATH : "${cudatoolkit}/include" \
      --prefix LIBRARY_PATH : "${cudatoolkit}/lib" \
      --set TRITON_LIBCUDA_PATH "${ldPath}" \
      --set TRITON_PTXAS_PATH "${cudatoolkit}/bin/ptxas" \
      --prefix PATH : ${lib.makeBinPath [ cudatoolkit clang ninja ]}
  '';

  passthru = {
    wsl = sglang.override { isWSL = true; };
  };

  meta = {
    description = "a high-performance serving framework for large language models and multimodal models";
    homepage = "https://github.com/sgl-project/sglang";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "sglang";
    skipBuild = true; # don't ever build this on github actions - it's quite heavy!
  };
}
