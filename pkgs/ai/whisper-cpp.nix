{ lib, darwin, stdenv, clangStdenv, fetchFromGitHub, SDL2 }:
let
  inherit (stdenv) isAarch64 isDarwin;
  isM1 = isDarwin && isAarch64;
  osSpecific =
    if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate ]
    else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
    else [ ];
  version = "1.4.0";
in
clangStdenv.mkDerivation rec {
  name = "whisper.cpp";
  src = fetchFromGitHub {
    owner = "ggerganov";
    repo = name;
    rev = "v${version}";
    hash = "sha256-176MpooVQrq1dXC62h8Yyyhw6IjCA50tp1J4DQPSePQ=";
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

  meta = with lib; {
    description = "Port of OpenAI's Whisper model in C/C++";
    homepage = "https://github.com/ggerganov/whisper.cpp";
    mainProgram = "whisper";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
