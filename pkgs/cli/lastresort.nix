# [lastresort](https://github.com/ctsrc/Base256) is a base256 encoder/decoder
{ lib, fetchFromGitHub, rustPlatform }:
let
  pname = "lastresort";
  version = "0.4.0";
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "ctsrc";
    repo = "Base256";
    rev = "v${version}";
    sha256 = "sha256-wwwm7x42Fk7Hsf1rE+dKLQJGTkmZnbFGDl5OX3gJ1rU=";
  };

  cargoSha256 = "sha256-tt5B8jt3DSb7LWCCDWITpe9XD/EmFbGubUmlysFqRuM=";

  meta = with lib; {
    description = "Encode and decode data in base 256 easily typed words";
    homepage = "https://github.com/ctsrc/Base256";
    license = licenses.isc;
    mainProgram = "lastresort";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
