{ lib, system, darwin, stdenv, clangStdenv, fetchFromGitHub, cmake }:
let
  inherit (stdenv) isAarch64 isDarwin;
  apple_gpu = isDarwin && isAarch64;
  osSpecific = with darwin.apple_sdk_11_0.frameworks; if isDarwin then ([ Accelerate ] ++ (if apple_gpu then [ CoreML MetalKit MetalPerformanceShaders MetalPerformanceShadersGraph ] else [ ])) else [ ];
  version = "master-9d0693b";
in
clangStdenv.mkDerivation rec {
  inherit version;
  name = "llama.cpp";
  src = fetchFromGitHub {
    owner = "ggerganov";
    repo = name;
    rev = "refs/tags/${version}";
    hash = "sha256-FOThm84jsNXbIVjPVqifWbarT2Gn0CbTReFf+E9s+kg=";
  };

  postPatch =
    if apple_gpu then ''
      substituteInPlace ./ggml-metal.m --replace '[[NSBundle mainBundle] pathForResource:@"ggml-metal" ofType:@"metal"];' "@\"$out/ggml-metal.metal\";"
    '' else "";

  cmakeFlags = [
    "-DLLAMA_BUILD_SERVER=ON"
  ] ++ (lib.optionals (system == "aarch64-darwin") [
    "-DCMAKE_C_FLAGS=-D__ARM_FEATURE_DOTPROD=1"
    "-DLLAMA_METAL=ON"
  ]);
  installPhase = ''
    mkdir -p $out/bin
    cp ../ggml-metal.metal $out/.
    mv ./bin/main $out/bin/llama
    mv ./bin/perplexity $out/bin/llama-perplexity
    mv ./bin/quantize $out/bin/llama-quantize
    mv ./bin/quantize-stats $out/bin/llama-quantize-stats
    mv ./bin/server $out/bin/llama-server
  '';
  buildInputs = osSpecific;
  nativeBuildInputs = [ cmake ];

  meta = with lib; {
    description = "Port of Facebook's LLaMA model in C/C++";
    homepage = "https://github.com/ggerganov/llama.cpp";
    mainProgram = "llama";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
