{ lib, darwin, stdenv, clangStdenv, fetchFromGitHub }:
let
  inherit (stdenv) isAarch64 isDarwin;
  isM1 = isDarwin && isAarch64;
  osSpecific =
    if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate ]
    else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
    else [ ];
  name = "starcoder.cpp";
  version = "0.0.0";
in
clangStdenv.mkDerivation {
  inherit name version;
  src = fetchFromGitHub {
    owner = "bigcode-project";
    repo = name;
    rev = "8d4b584506663398180e2e2568ba99b6cbba3a27";
    hash = "sha256-NKOApP+xAz3qCT3I3s4QVPgIGHbeADDw+Jfx7JmZMNU=";
  };
  postBuild = ''
    make quantize
  '';
  installPhase = ''
    mkdir -p $out/bin
    mv ./main $out/bin/starcoder
    mv ./quantize $out/bin/starcoder-quantize
  '';
  buildInputs = osSpecific;

  meta = with lib; {
    description = "C++ implementation for StarCoder";
    homepage = "https://github.com/bigcode-project/starcoder.cpp";
    mainProgram = "starcoder";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
