# [`llm`](https://github.com/rustformers/llm) is a port of [`llama.cpp`](https://github.com/ggerganov/llama.cpp) in rust!
{ lib, stdenv, darwin, fetchFromGitHub, rustPlatform, openssl, pkg-config }:
let
  inherit (stdenv) isAarch64 isDarwin;
  isM1 = isDarwin && isAarch64;
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
  buildInputs = [ openssl ];
  nativeBuildInputs = [ pkg-config ];

  cargoHash = "sha256-/Bsk5RFGuyUg9AUmiHh6HdLBAEuc50o4bIQPsTHS67M=";

  meta = with lib; {
    description = "Run inference for Large Language Models on CPU, with Rust";
    homepage = "https://github.com/rustformers/llm";
    license = licenses.mit;
    mainProgram = "llm";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
