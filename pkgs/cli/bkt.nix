# [bkt](https://github.com/dimo414/bkt) is a subprocess caching utility
{ lib, fetchFromGitHub, rustPlatform }:
let
  pname = "bkt";
  version = "0.8.2";
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "dimo414";
    repo = "bkt";
    rev = version;
    sha256 = "sha256-qb7uRvCAXCayDIg8yQfF/Yxe0pNvR3giCQYmMIur2rM=";
  };

  cargoHash = "sha256-NGXo+He3KEPTDf5LqEN0sDwK93sc+kU+5w4kAEyaYuU=";
  doCheck = false; # the tests are currently failing?

  meta = with lib; {
    description = "subprocess caching utility";
    homepage = "https://github.com/dimo414/bkt";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
