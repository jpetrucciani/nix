# [`whisper.cpp`](https://github.com/ggerganov/whisper.cpp) is a port of [OpenAI's Whisper](https://openai.com/research/whisperg) model in C/C++
{ lib
, symlinkJoin
, darwin
, gnumake
, stdenv
, whisper-cpp
, clangStdenv
, cudatoolkit
, fetchFromGitHub
, SDL2
, cuda ? false
}:
let
  inherit (lib) optionals;
  inherit (stdenv) isAarch64 isDarwin;
  isM1 = isDarwin && isAarch64;
  osSpecific =
    if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate MetalKit MetalPerformanceShaders MetalPerformanceShadersGraph ]
    else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
    else [ ];
  ifCuda = value: if cuda then value else null;
  cudatoolkit_joined = symlinkJoin {
    name = "${cudatoolkit.name}-merged";
    paths = [
      cudatoolkit.lib
      cudatoolkit.out
    ];
  };
  version = "1.6.1";
  owner = "ggerganov";
  repo = "whisper.cpp";
in
clangStdenv.mkDerivation {
  inherit version;
  name = repo;
  src = fetchFromGitHub {
    inherit owner repo;
    rev = "refs/tags/v${version}";
    hash = "sha256-0QVaBV/kOMBHon0L8L+LDrFra2forqy441z7KLPNaa8=";
  };

  # flags
  WHISPER_CUBLAS = ifCuda "1";

  postBuild = ''
    make server
    make stream
  '';
  installPhase = ''
    mkdir -p $out/bin
    mv ./main $out/bin/whisper
    mv ./stream $out/bin/whisper-stream
    mv ./server $out/bin/whisper-server
  '';

  buildInputs = [
    SDL2
  ] ++ osSpecific;
  nativeBuildInputs = [ gnumake ] ++ (optionals cuda [ cudatoolkit_joined ]);

  passthru.cuda = whisper-cpp.override { cuda = true; };

  meta = with lib; {
    description = "Port of OpenAI's Whisper model in C/C++";
    homepage = "https://github.com/ggerganov/whisper.cpp";
    mainProgram = "whisper";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
