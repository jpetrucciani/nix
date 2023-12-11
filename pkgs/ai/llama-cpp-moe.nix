{ lib
, system
, symlinkJoin
, darwin
, stdenv
, clangStdenv
, fetchFromGitHub
, cmake
, common-updater-scripts
, coreutils
, curl
, jq
, nix
, nix-prefetch-github
, ninja
, writeScript
, llama-cpp-moe
, cudatoolkit
, clblas
, clblast
, ocl-icd
, blas
, opencl-headers
, openmpi
, pkg-config
, cuda ? false
, opencl ? false
}:
let
  inherit (lib) optionals;
  inherit (stdenv) isAarch64 isDarwin;
  isM1 = isDarwin && isAarch64;
  osSpecific =
    if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate MetalKit MetalPerformanceShaders MetalPerformanceShadersGraph ]
    else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
    else [
      clblas
      clblast
      ocl-icd
      opencl-headers
      blas
    ];

  cudatoolkit_joined = symlinkJoin {
    name = "${cudatoolkit.name}-merged";
    paths = [
      cudatoolkit.lib
      cudatoolkit.out
    ] ++ lib.optionals (lib.versionOlder cudatoolkit.version "11") [
      "${cudatoolkit}/targets/${system}"
    ];
  };
  version = "moe";
  owner = "ggerganov";
  repo = "llama.cpp";
in
clangStdenv.mkDerivation {
  inherit version;
  name = "llama-cpp-moe";
  src = fetchFromGitHub {
    inherit owner repo;
    rev = "f1cbfabd642a18f6db0435ea67a3f5c890d801bc";
    hash = "sha256-lqe6EyqJ6kcx/SUCCm8Q3vTFBXXDVGCwNvz5qtct5jI=";
  };

  postPatch =
    if isM1 then ''
      substituteInPlace ./ggml-metal.m --replace '[bundle pathForResource:@"ggml-metal" ofType:@"metal"];' "@\"$out/ggml-metal.metal\";"
    '' else "";

  cmakeFlags = [
    "-DLLAMA_BUILD_SERVER=ON"
    "-DLLAMA_MPI=ON"
    "-DCMAKE_SKIP_BUILD_RPATH=ON"
  ] ++ (optionals isM1 [
    "-DCMAKE_C_FLAGS=-D__ARM_FEATURE_DOTPROD=1"
    "-DLLAMA_METAL=ON"
  ]) ++ (optionals cuda [
    "-DLLAMA_CUBLAS=ON"
  ]) ++ (optionals (!isM1) [
    "-DLLAMA_BLAS=ON"
    (if opencl then "-DLLAMA_CLBLAST=ON" else "-DLLAMA_BLAS_VENDOR=OpenBLAS")
  ]);
  installPhase = ''
    mkdir -p $out/bin
    cp ../ggml-metal.metal $out/.
    mv ./bin/main $out/bin/llama
    mv ./bin/perplexity $out/bin/llama-perplexity
    mv ./bin/quantize $out/bin/llama-quantize
    mv ./bin/quantize-stats $out/bin/llama-quantize-stats
    mv ./bin/server $out/bin/llama-server
    mv ./bin/llava-cli $out/bin/llava
  '';
  buildInputs = [ openmpi ] ++ osSpecific;
  nativeBuildInputs = [ cmake ninja pkg-config ] ++ (optionals cuda [ cudatoolkit_joined ]);

  passthru.cuda = llama-cpp-moe.override { cuda = true; };
  passthru.opencl = llama-cpp-moe.override { opencl = true; };

  meta = with lib; {
    description = "Port of Facebook's LLaMA model in C/C++";
    homepage = "https://github.com/ggerganov/llama.cpp";
    mainProgram = "llama";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
