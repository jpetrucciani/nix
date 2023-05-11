{ lib, fetchFromGitHub, rustPlatform }:
let
  pname = "llm";
  version = "0.1.1";
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "rustformers";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-yvLz3u5hMD1z+HyNjaCHLh+KZl1DNvfUedGe8pr3ayM=";
    fetchSubmodules = true;
  };

  cargoHash = "sha256-TuN729VwCGsRHjN6LHEATfRUMGYZuEWl8vi/qz7DAf4=";

  meta = with lib; {
    description = "Run inference for Large Language Models on CPU, with Rust";
    homepage = "https://github.com/rustformers/llm";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
