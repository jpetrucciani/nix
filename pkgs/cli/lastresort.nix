# [lastresort](https://github.com/ctsrc/Base256) is a base256 encoder/decoder
{ lib, fetchFromGitHub, rustPlatform }:
let
  pname = "lastresort";
  version = "0.4.2";
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "ctsrc";
    repo = "Base256";
    rev = "v${version}";
    sha256 = "sha256-nruXdanshJow4imQY8tshHde96ek1Ro1KK0U2V9jAs4=";
  };

  cargoHash = "sha256-icLggjM7sppAstmS1w1IzuTasC7tYgBmD7ubayjP25E=";

  meta = with lib; {
    description = "Encode and decode data in base 256 easily typed words";
    homepage = "https://github.com/ctsrc/Base256";
    license = licenses.isc;
    mainProgram = "lastresort";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
