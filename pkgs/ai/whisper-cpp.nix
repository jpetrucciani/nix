{ darwin, stdenv, clangStdenv, fetchFromGitHub, SDL2 }:
let
  inherit (stdenv) isAarch64 isDarwin;
  version = "1.3.0";
  osSpecific = with darwin.apple_sdk.frameworks; if isDarwin then ([ Accelerate ] ++ (if !isAarch64 then [ CoreGraphics CoreVideo ] else [ ])) else [ ];
in
clangStdenv.mkDerivation rec {
  name = "whisper.cpp";
  src = fetchFromGitHub {
    owner = "ggerganov";
    repo = name;
    rev = "v${version}";
    hash = "sha256-PJUQ2IoocPv1bWRv3eXzB1aWlUZ8zGFgdwIOk2stCoo=";
  };
  postBuild = ''
    make stream
  '';
  installPhase = ''
    mkdir -p $out/bin
    mv ./main $out/bin/whisper
    mv ./stream $out/bin/whisper-stream
  '';
  buildInputs = [
    SDL2
  ] ++ osSpecific;
}
