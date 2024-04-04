# [hunt](https://github.com/LyonSyonII/hunt-rs) is a simplified find command in rust
{ lib, fetchFromGitHub, rustPlatform }:
let
  pname = "hunt";
  version = "2.0.0";
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "LyonSyonII";
    repo = "hunt-rs";
    rev = "refs/tags/v${version}";
    sha256 = "sha256-TwxNVT2x9Y0jnLXiIquf/bQ31B+2VwFfh9EFbJQHpt4=";
  };

  cargoSha256 = "sha256-GU3AXZJ8yGFnj0SXRezS/YI6aS/lJowwo+GBBv5wNik=";

  meta = with lib; {
    description = "simplified find command made with rust";
    homepage = "https://github.com/LyonSyonII/hunt-rs";
    license = licenses.mit;
    mainProgram = "hunt";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
