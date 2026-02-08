{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, sqlite
, stdenv
, darwin
}:

rustPlatform.buildRustPackage rec {
  pname = "mica";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "gemologic";
    repo = "mica";
    rev = "v${version}";
    hash = "sha256-tA77aoqlSdOkN+gscHUV8+LIoLALt5z10ovpPVL3Svc=";
  };

  cargoHash = "sha256-kJK+akh9/IlJ2zhuz3SvPAh3ajEGmzjHMhN9JWSi3go=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    sqlite
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
  ];

  meta = {
    description = "An experimental TUI for managing nix environments";
    homepage = "https://github.com/gemologic/mica";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "mica";
  };
}
