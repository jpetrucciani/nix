{ lib, fetchFromGitHub, rustPlatform }:
let
  pname = "killport";
  version = "0.6.0";
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "jkfran";
    repo = pname;
    # rev = "v${version}";
    rev = "b9346e790e447b2f6719ee7a136d37a460a4f9f4";
    sha256 = "sha256-Kj1GsZiwkdKu8oP2fPjSic5uYN496/3FXALZxZz+9eg=";
  };

  cargoHash = "sha256-sdQduuapF7ZuTCGqrt4swpM9IWnd8EmKptrr+1QEye4=";

  meta = with lib; {
    description = "Easily kill processes running on a specified port";
    homepage = "https://github.com/jkfran/killport";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
