{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, sqlite

}:

rustPlatform.buildRustPackage rec {
  pname = "mica";
  version = "0.0.3";

  src = fetchFromGitHub {
    owner = "gemologic";
    repo = "mica";
    rev = "v${version}";
    hash = "sha256-CXxwv3CYIOlcYJzMCsqMpQCPEE0MbOTSRNa4oBCMrVw=";
  };

  cargoHash = "sha256-kJK+akh9/IlJ2zhuz3SvPAh3ajEGmzjHMhN9JWSi3go=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    sqlite
  ];

  meta = {
    description = "An experimental TUI for managing nix environments";
    homepage = "https://github.com/gemologic/mica";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "mica";
  };
}
