# [rainfrog](https://github.com/achristmascarl/rainfrog) is a database management tui for postgres
{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, sqlite
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

  buildInputs = [ sqlite ];

  meta = {
    description = "A database management tui for postgres";
    homepage = "https://github.com/achristmascarl/rainfrog";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "rainfrog";
  };
}
