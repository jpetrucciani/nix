# [mermaid-rs-renderer](https://github.com/1jehuang/mermaid-rs-renderer) is a fast native rust mermaid diagram renderer
{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "mermaid-rs-renderer";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "1jehuang";
    repo = "mermaid-rs-renderer";
    rev = "v${version}";
    hash = "sha256-g2SIz9ccq1SClbiHDM/vVbwvncCp0eGCm49yvjttmrY=";
  };

  cargoHash = "sha256-pZRIpkTBfPQ5asgSzHJBlLsHLMh6uZ0jMRd8sX9gFL8=";

  meta = {
    description = "A fast native Rust Mermaid diagram renderer. No browser required. 500-1000x faster than mermaid-cli";
    homepage = "https://github.com/1jehuang/mermaid-rs-renderer";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "mmdr";
  };
}
