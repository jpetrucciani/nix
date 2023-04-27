{ lib, fetchFromGitHub, rustPlatform }:
let
  pname = "bkt";
  version = "0.6.1";
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "dimo414";
    repo = "bkt";
    rev = version;
    sha256 = "sha256-NgNXuTpI1EzgmxKRsqzxTOlQi75BHCcbjFnouhnfDDM=";
  };

  cargoSha256 = "sha256-PvcKviyXtiHQCHgJLGR2Mr+mPpTd06eKWQ5h6eGdl40=";

  meta = with lib; {
    description = "subprocess caching utility";
    homepage = "https://github.com/dimo414/bkt";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
