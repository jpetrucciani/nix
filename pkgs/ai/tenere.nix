# [tenere](https://github.com/pythops/tenere) is a TUI interface for LLMs
{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, libgit2
, oniguruma
, zlib
, stdenv
, darwin
}:

rustPlatform.buildRustPackage rec {
  pname = "tenere";
  version = "0.11.1";

  src = fetchFromGitHub {
    owner = "pythops";
    repo = "tenere";
    rev = "v${version}";
    hash = "sha256-uvv7URcdpKBUc04LsEigjt7iQhiEgiglBP5iwH6bQRI=";
  };

  cargoHash = "sha256-mz/lRh5+GWQrU7w2P4J3KV9Fz8rvc14JswPKO5UxrIs=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libgit2
    oniguruma
    zlib
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.AppKit
    darwin.apple_sdk.frameworks.CoreGraphics
    darwin.apple_sdk.frameworks.Security
  ];

  env = {
    RUSTONIG_SYSTEM_LIBONIG = true;
  };

  meta = with lib; {
    description = "TUI interface for LLMs written in Rust";
    homepage = "https://github.com/pythops/tenere";
    changelog = "https://github.com/pythops/tenere/blob/${src.rev}/CHANGELOG.md";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "tenere";
  };
}
