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
  name = "falcon.cpp";
  src = fetchFromGitHub {
    owner = "nikisalli";
    repo = name;
    rev = "fcb95afe6a38366f6d1c7c4741cde5cead77107b";
    hash = "sha256-Rdb9KPnNeQFH7NhcesvNZPDsLpzsfaBl7w/+c3QByzw=";
  };
  buildPhase = ''
    make
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp ./main $out/bin/falcon
    mv ./quantize $out/bin/falcon-quantize
  '';
  buildInputs = osSpecific;

  meta = with lib; {
    description = "c++ implementation of falcon";
    homepage = "https://github.com/nikisalli/falcon.cpp";
    mainProgram = "chat";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
