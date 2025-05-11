# [rainfrog](https://github.com/achristmascarl/rainfrog) is a database management tui for postgres
{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, sqlite
, stdenv
, darwin
}:

rustPlatform.buildRustPackage rec {
  pname = "rainfrog";
  version = "0.1.15";

  src = fetchFromGitHub {
    owner = "achristmascarl";
    repo = "rainfrog";
    rev = "v${version}";
    hash = "sha256-EPF6GoziVhgJlY0adTkH5nxniHsQMcc8Qitx/WdPzgM=";
  };

  cargoHash = "sha256-WWkX0TlvFk2ZFwTzFqqquR6vaWC9qxQxJC+rIQ4D00Q=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    sqlite
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.AppKit
    darwin.apple_sdk.frameworks.CoreFoundation
    darwin.apple_sdk.frameworks.CoreGraphics
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];

  meta = {
    description = "A database management tui for postgres";
    homepage = "https://github.com/achristmascarl/rainfrog";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "rainfrog";
  };
}
