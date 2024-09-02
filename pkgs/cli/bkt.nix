# [bkt](https://github.com/dimo414/bkt) is a subprocess caching utility
{ lib, fetchFromGitHub, rustPlatform }:
let
  pname = "bkt";
  version = "0.8.0";
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "dimo414";
    repo = "bkt";
    rev = version;
    sha256 = "sha256-XQK7oZfutqCvFoGzMH5G5zoGvqB8YaXSdrwjS/SVTNU=";
  };

  cargoSha256 = "sha256-Pl+a+ZpxaguRloH8R7x4FmYpTwTUwFrYy7AS/5K3L+8=";

  meta = with lib; {
    description = "subprocess caching utility";
    homepage = "https://github.com/dimo414/bkt";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
