# [sglang](https://github.com/sgl-project/sglang) is a high-performance serving framework for large language models and multimodal models.
{ sglang, lib, uv-nix, cudatoolkit, clang, ninja, python313, version ? "0.5.6-dflash", lockHash ? "sha256-58eN5oohBiNzhHiNZAOzmWyQqwBJeRKynfvJItspsrM=", isWSL ? false, includePin ? false }:
let
  ldPath = if isWSL then "/usr/lib/wsl/lib" else "/run/opengl-driver/lib";
  runtimePythonPath = lib.concatStringsSep ":" [
    "${python313.pkgs.imageio}/${python313.sitePackages}"
    "${python313.pkgs."imageio-ffmpeg"}/${python313.sitePackages}"
  ];
in
uv-nix.buildUvPackage rec {
  inherit version lockHash includePin;
  pname = "sglang";

  lockUrl = "https://static.g7c.us/lock/uv/sglang/${version}.lock";
  extraDependencies = [ ];
  cudaSupport = true;

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
