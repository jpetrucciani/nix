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
  name = "alpaca.cpp";
  src = fetchFromGitHub {
    owner = "antimatter15";
    repo = name;
    rev = "81bd894";
    hash = "sha256-izeL66to0/hwTsZopEPz1e08TOUoVSWrA1YKbBYnUTk=";
  };
  buildPhase = ''
    make chat
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp ./chat $out/bin/chat
    mv ./chat $out/bin/alpaca-chat
  '';
  buildInputs = osSpecific;

  meta = with lib; {
    description = "Locally run an Instruction-Tuned Chat-Style LLM";
    homepage = "https://github.com/antimatter15/alpaca.cpp";
    mainProgram = "chat";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
