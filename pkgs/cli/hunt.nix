{ lib, fetchFromGitHub, rustPlatform }:
let
  pname = "hunt";
  version = "1.7.6";
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "LyonSyonII";
    repo = "hunt-rs";
    rev = "refs/tags/v${version}";
    sha256 = "sha256-mNQY2vp4wNDhVqrFNVS/RBXVi9EMbTZ6pE0Z79dLUeM=";
  };

  cargoSha256 = "sha256-hjvJ9E5U6zGSWUXNDdu0GwUcd7uZeconfjiCSaEzZXU=";

  meta = with lib; {
    description = "simplified find command made with rust";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
