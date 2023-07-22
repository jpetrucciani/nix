{ lib, darwin, stdenv, clangStdenv, fetchFromGitHub, bash, python311, cudatoolkit, koboldcpp, cuda ? false }:
let
  inherit (lib) optionals;
  inherit (stdenv) isAarch64 isDarwin;
  isM1 = isDarwin && isAarch64;
  osSpecific =
    if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate MetalKit MetalPerformanceShaders MetalPerformanceShadersGraph ]
    else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
    else [ ];
  version = "1.36";
  owner = "LostRuins";
  repo = "koboldcpp";
  python = python311.withPackages (p: with p; [
    numpy
    sentence-transformers
    sentencepiece
  ]);
in
clangStdenv.mkDerivation rec {
  inherit version;
  name = repo;
  src = fetchFromGitHub {
    inherit owner repo;
    rev = "refs/tags/v${version}";
    hash = "sha256-iWxoTXxLGAzju8EzFbUANzSQNxBUUs3Q7FqytCeoh90=";
  };

  postPatch = optionals isM1 ''
    substituteInPlace ./ggml-metal.m --replace '[bundle pathForResource:@"ggml-metal" ofType:@"metal"];' "@\"$out/lib/ggml-metal.metal\";"
  '';

  LLAMA_METAL = optionals isM1 "1";
  LLAMA_CUBLAS = optionals cuda "1";

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
  buildInputs = osSpecific;
  nativeBuildInputs = [ ] ++ (optionals cuda [ cudatoolkit ]);
  passthru.cuda = koboldcpp.override { cuda = true; };

  meta = with lib; {
    description = "A simple one-file way to run various GGML models with KoboldAI's UI";
    homepage = "https://github.com/LostRuins/koboldcpp";
    mainProgram = "llama";
    license = licenses.agpl3;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
