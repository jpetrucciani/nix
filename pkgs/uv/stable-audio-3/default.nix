# [Stable Audio 3](https://github.com/Stability-AI/stable-audio-3) generates and edits audio using CUDA.
{ stable-audio-3
, lib
, stdenv
, uv-nix
, python312
, makeWrapper
, addDriverRunpath
, isWSL ? false
}:
let
  pyproject = lib.importTOML ./pyproject.toml;
  uvEnv = uv-nix.mkEnv {
    name = "stable-audio-3";
    workspaceRoot = ./.;
    gitignore = false;
    python = python312;
    enableCuda = true;
    pyprojectOverrides = final: prev: {
      stable-audio-3-service = prev.stable-audio-3-service.overrideAttrs {
        src = lib.fileset.toSource {
          root = ./.;
          fileset = lib.fileset.unions [
            ./pyproject.toml
            (lib.fileset.fileFilter (file: file.hasExt "py") ./stable_audio_service)
          ];
        };
      };
      flash-attn = prev.flash-attn.overrideAttrs (old: {
        buildInputs = (old.buildInputs or [ ]) ++ [ final.nvidia-cuda-runtime-cu12 ];
        preFixup = (old.preFixup or "") + ''
          addAutoPatchelfSearchPath ${final.nvidia-cuda-runtime-cu12}
        '';
      });
    };
  };
  driverPath = if isWSL then "/usr/lib/wsl/lib" else "${addDriverRunpath.driverLink}/lib";
in
stdenv.mkDerivation {
  pname = "stable-audio-3";
  inherit (pyproject.project) version;
  dontUnpack = true;
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    sitePackages=${uvEnv}/${python312.sitePackages}
    libraries="$sitePackages/torch/lib"
    for directory in "$sitePackages"/nvidia/*/lib; do
      libraries="$libraries:$directory"
    done
    makeWrapper ${uvEnv}/bin/stable-audio-3 "$out/bin/stable-audio-3" \
      --prefix LD_LIBRARY_PATH : "$libraries:${driverPath}" \
      --set PYTHONNOUSERSITE 1
    ln -s ${uvEnv}/bin/stable-audio-3-benchmark "$out/bin/stable-audio-3-benchmark"
    runHook postInstall
  '';

  passthru = {
    inherit uvEnv;
    wsl = stable-audio-3.override { isWSL = true; };
  };

  meta = {
    description = "CUDA inference service for Stable Audio 3 sound effects, music, and audio editing";
    homepage = "https://github.com/Stability-AI/stable-audio-3";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.jpetrucciani ];
    mainProgram = "stable-audio-3";
    platforms = [ "x86_64-linux" ];
    skipBuild = true; # The CUDA wheels are too large for routine CI builds.
  };
}
