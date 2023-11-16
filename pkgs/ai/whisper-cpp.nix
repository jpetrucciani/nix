{ lib, system, symlinkJoin, darwin, gnumake, stdenv, whisper-cpp, clangStdenv, cudatoolkit, fetchFromGitHub, SDL2, cuda ? false }:
let
  inherit (lib) optionals;
  inherit (stdenv) isAarch64 isDarwin;
  isM1 = isDarwin && isAarch64;
  osSpecific =
    if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate MetalKit MetalPerformanceShaders MetalPerformanceShadersGraph ]
    else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
    else [ ];
  version = "1.5.0";
  ifCuda = value: if cuda then value else null;
  cudatoolkit_joined = symlinkJoin {
    name = "${cudatoolkit.name}-merged";
    paths = [
      cudatoolkit.lib
      cudatoolkit.out
    ] ++ lib.optionals (lib.versionOlder cudatoolkit.version "11") [
      "${cudatoolkit}/targets/${system}"
    ];
  };
in
clangStdenv.mkDerivation rec {
  name = "whisper.cpp";
  src = fetchFromGitHub {
    owner = "ggerganov";
    repo = name;
    rev = "refs/tags/v${version}";
    hash = "sha256-V6mK4bE8wbNRV+v/BilXWToDQPg34dyOcV0kqqcymc8=";
  };

  # flags
  WHISPER_CUBLAS = ifCuda "1";

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
