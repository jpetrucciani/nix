{ lib, stdenv, darwin, fetchFromGitHub, rustPlatform, openssl, pkg-config }:
let
  inherit (stdenv) isAarch64 isDarwin;
  isM1 = isDarwin && isAarch64;
  osSpecific =
    if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate MetalKit MetalPerformanceShaders MetalPerformanceShadersGraph ]
    else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
    else [ ];
  pname = "llm";
  version = "0.0.0";
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "rustformers";
    repo = pname;
    rev = "7f13bb90f678e2bdf70d221f1b790fab55cb4d7f";
    sha256 = "sha256-h4PSMMa7wY50fffcgkvpah5ACJWhekrwHyTq2hzwtbo=";
    fetchSubmodules = true;
  };
  buildInputs = [
    openssl
  ] ++ osSpecific;
  nativeBuildInputs = [ pkg-config ];

  cargoHash = "sha256-xDloCgOv12BcueEx/kpM/2810Us7rVk8RnIFnaCjW2M=";

  meta = with lib; {
    description = "Run inference for Large Language Models on CPU, with Rust";
    homepage = "https://github.com/rustformers/llm";
    license = licenses.mit;
    mainProgram = "llm";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
