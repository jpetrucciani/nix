{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.3";
  pname = "horcrux";

  src = fetchFromGitHub {
    owner = "jesseduffield";
    repo = "horcrux";
    rev = "v${version}";
    sha256 = "1r1gwzg6hlfdagbzqgbxdj4b7nbid9b6pdxyrgzy4mla65vcdk0p";
  };

  # vendorSha256 = lib.fakeSha256;
  vendorSha256 = "pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "Split your file into encrypted fragments so that you don't need to remember a passcode";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
