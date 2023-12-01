{ lib
, darwin
, stdenv
, llvmPackages_14
, fetchFromGitHub
, bash
, python311
, cudatoolkit
, koboldcpp
, blas
, clblas
, clblast
, ocl-icd
, openblas
, opencl-headers
, cuda ? false
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
    ];
  version = "1.51";
  owner = "LostRuins";
  repo = "koboldcpp";
  python = python311.withPackages (p: with p; [
    numpy
    sentence-transformers
    sentencepiece
  ]);
in
llvmPackages_14.stdenv.mkDerivation rec {
  inherit version;
  name = repo;
  src = fetchFromGitHub {
    inherit owner repo;
    rev = "refs/tags/v${version}";
    hash = "sha256-OynRJ4K0W+krX6NpKsHD0Kw08H2sKUb/E1zhzFlCips=";
  };

  postPatch = optionals isM1 ''
    substituteInPlace ./ggml-metal.m --replace '[bundle pathForResource:@"ggml-metal" ofType:@"metal"];' "@\"$out/lib/ggml-metal.metal\";"
  '';

  LLAMA_CLBLAST = optionals (!isM1) 1;
  LLAMA_CUBLAS = optionals cuda 1;
  LLAMA_METAL = optionals isM1 1;
  LLAMA_OPENBLAS = 1;

  installPhase = ''
    mkdir -p $out/bin $out/lib
    cp -r . $out/lib/.
    cat <<EOF >$out/bin/koboldcpp
    #!${bash}/bin/bash
    export PORT="\''${PORT:-8100}"
    ${python}/bin/python $out/lib/koboldcpp.py "\$@" "\$MODEL" "\$PORT"
    EOF
    chmod +x $out/bin/koboldcpp
  '';
  buildInputs = [ blas openblas ] ++ osSpecific;
  nativeBuildInputs = optionals cuda [ cudatoolkit ];
  passthru.cuda = koboldcpp.override { cuda = true; };

  meta = with lib; {
    description = "A simple one-file way to run various GGML models with KoboldAI's UI";
    homepage = "https://github.com/LostRuins/koboldcpp";
    mainProgram = "koboldcpp";
    license = licenses.agpl3;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
