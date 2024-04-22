# [koboldcpp](https://github.com/LostRuins/koboldcpp) is a fork of llama-cpp based on backwards compatibility
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
  version = "1.63";
  owner = "LostRuins";
  repo = "koboldcpp";
  py = python311.withPackages (p: with p; [
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
    hash = "sha256-LAAINN49gjJPye3rfbA8oh29/qcVVk99SSRZD8WQNKQ=";
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
    ${py}/bin/python $out/lib/koboldcpp.py "\$@" "\$MODEL" "\$PORT"
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
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
