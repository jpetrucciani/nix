{ stdenv, lib, fetchFromGitHub, fetchpatch, rustPlatform, ... }:
let
  pname = "killport";
  version = "0.6.0";
  og = fetchFromGitHub {
    owner = "jkfran";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-dbV2NsAdLp/huVnyZ38cK29Cl+YC5tCVHM3kOIff13o=";
  };
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = stdenv.mkDerivation {
    name = "${pname}-patched";
    src = og;
    patches = [
      (fetchpatch {
        url = "https://github.com/jpetrucciani/killport/commit/44c4de09ab15a1a8abf6fdecee973d78aca537db.patch";
        hash = "sha256-C55NHqYQs9zO34cu2Z/q72t6vqbAkDk05sn9caKteRk=";
      })
    ];
    buildPhase = ''
      mkdir -p $out
      cp -R . $out/.
    '';
  };

  cargoHash = "sha256-sdQduuapF7ZuTCGqrt4swpM9IWnd8EmKptrr+1QEye4=";

  meta = with lib; {
    description = "";
    homepage = "https://github.com/jkfran/killport";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
