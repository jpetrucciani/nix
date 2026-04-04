# [sglang](https://github.com/sgl-project/sglang) is a high-performance serving framework for large language models and multimodal models.
{ sglang, lib, uv-nix, cudatoolkit, clang, version ? "0.5.6-dflash", lockHash ? "sha256-58eN5oohBiNzhHiNZAOzmWyQqwBJeRKynfvJItspsrM=", isWSL ? false, includePin ? false }:
let
  ldPath = if isWSL then "/usr/lib/wsl/lib" else "/run/opengl-driver/lib";
in
uv-nix.buildUvPackage rec {
  inherit version lockHash includePin;
  pname = "sglang";

  lockUrl = "https://static.g7c.us/lock/uv/sglang/${version}.lock";
  extraDependencies = [ ];
  cudaSupport = true;

  postInstall = ''
    wrapProgram $out/bin/sglang \
      --set LD_LIBRARY_PATH "${ldPath}" \
      --set TRITON_LIBCUDA_PATH "${ldPath}" \
      --set TRITON_PTXAS_PATH "${cudatoolkit}/bin/ptxas" \
      --prefix PATH : ${clang}/bin
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
