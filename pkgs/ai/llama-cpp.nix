{ lib, darwin, stdenv, clangStdenv, fetchFromGitHub, cmake, writeScript }:
let
  inherit (lib) optionals;
  inherit (stdenv) isAarch64 isDarwin;
  isM1 = isDarwin && isAarch64;
  osSpecific =
    if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate MetalKit MetalPerformanceShaders MetalPerformanceShadersGraph ]
    else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
    else [ ];
  version = "master-254a7a7";
in
clangStdenv.mkDerivation rec {
  inherit version;
  name = "llama.cpp";
  src = fetchFromGitHub {
    owner = "ggerganov";
    repo = name;
    rev = "refs/tags/${version}";
    hash = "sha256-QJ1BojxgXtJLNQkO85F6Ulsr8Pggb7dHb/nKNpnGRoE=";
  };

  postPatch =
    if isM1 then ''
      substituteInPlace ./ggml-metal.m --replace '[bundle pathForResource:@"ggml-metal" ofType:@"metal"];' "@\"$out/ggml-metal.metal\";"
    '' else "";

  cmakeFlags = [
    "-DLLAMA_BUILD_SERVER=ON"
  ] ++ (optionals isM1 [
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

  passthru.updateScript = writeScript "llama-cpp-update-script" ''
    #!/usr/bin/env nix-shell
    #!nix-shell -i bash -p curl common-updater-scripts nix-prefetch-github jq

    set -eu -o pipefail
    latest_version="$(curl -s https://api.github.com/repos/ggerganov/llama.cpp/releases/latest | jq --raw-output .tag_name)"
    latest_sha="$(nix-prefetch-github --rev "refs/tags/$latest_version" ggerganov llama.cpp | jq --raw-output .sha256)"
    update-source-version llama-cpp "$latest_version" "$latest_sha"
  '';

  meta = with lib; {
    description = "Port of Facebook's LLaMA model in C/C++";
    homepage = "https://github.com/ggerganov/llama.cpp";
    mainProgram = "llama";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
