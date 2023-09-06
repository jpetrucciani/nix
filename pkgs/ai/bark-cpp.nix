{ lib, darwin, stdenv, clangStdenv, fetchFromGitHub }:
let
  inherit (stdenv) isAarch64 isDarwin;
  isM1 = isDarwin && isAarch64;
  osSpecific =
    if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate ]
    else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
    else [ ];
in
clangStdenv.mkDerivation rec {
  name = "bark.cpp";
  src = fetchFromGitHub {
    owner = "PABannier";
    repo = name;
    rev = "79b2cbeb4e2e877c85f7b6d7978e1901c86e3793";
    hash = "sha256-kpL2cPjx65xe08wcIiFG03lr6m+RO3+jOXg8xGcG6VI=";
  };
  buildPhase = ''
    make
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp ./main $out/bin/bark
    mv ./quantize $out/bin/bark-quantize
  '';
  buildInputs = osSpecific;

  meta = with lib; {
    description = "Port of Suno AI's Bark in C/C++ for fast inference ";
    homepage = "https://github.com/PABannier/bark.cpp";
    mainProgram = "bark";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
