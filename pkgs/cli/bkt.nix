# [bkt](https://github.com/dimo414/bkt) is a subprocess caching utility
{ lib, fetchFromGitHub, rustPlatform }:
let
  pname = "bkt";
  version = "0.7.1";
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "dimo414";
    repo = "bkt";
    rev = version;
    sha256 = "sha256-CMCO1afTWhXlWpy9D7txqI1FHxGDgdVdkKtyei6oFJU=";
  };

  cargoSha256 = "sha256-T4JT8GzKqsQQfe3zfst6gNEvdY7zs2h2H3s6slaRhYY=";

  meta = with lib; {
    description = "subprocess caching utility";
    homepage = "https://github.com/dimo414/bkt";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
