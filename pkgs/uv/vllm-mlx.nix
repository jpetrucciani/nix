# [vllm-mlx](https://github.com/waybarrios/vllm-mlx) is a multi-modal openAI-compatible server for Apple Silicon
{ lib, uv-nix, espeak-ng, python313, version ? "0.2.1", lockHash ? "sha256-Nk8Zb4SN3QqgIGwGgcVacysTZvfT932OVScMwd25geY=", includePin ? false }:
let
  name = "vllm-mlx";
in
uv-nix.buildUvPackage rec {
  inherit version lockHash includePin;
  pname = name;

  lockUrl = "https://static.g7c.us/lock/uv/${name}/${version}.lock";
  extraDependencies = [ "mlx-vlm==0.3.9" "vllm-mlx[audio]==0.2.1" ];
  postInstall = ''
    wrapProgram $out/bin/vllm-mlx \
      --prefix PATH : ${espeak-ng}/bin \
      --prefix DYLD_LIBRARY_PATH : ${python313.pkgs.mlx}/${python313.sitePackages}/mlx/lib
  '';

  meta = {
    changelog = "https://github.com/waybarrios/vllm-mlx/releases/tag/v${version}";
    description = "multi-modal openAI-compatible server for Apple Silicon";
    homepage = "https://github.com/waybarrios/vllm-mlx";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "vllm-mlx";
    skipBuild = true; # don't ever build this on github actions - it's quite heavy!
  };
}
