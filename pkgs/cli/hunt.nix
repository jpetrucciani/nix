# [hunt](https://github.com/LyonSyonII/hunt-rs) is a simplified find command in rust
{ lib, fetchFromGitHub, rustPlatform }:
let
  pname = "hunt";
  version = "2.4.0";
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "LyonSyonII";
    repo = "hunt-rs";
    rev = "refs/tags/v${version}";
    sha256 = "sha256-NKXZECtepuFg6qTuXF9Gnat/vnrygt3UOZb0YUKPqi8=";
  };

  cargoHash = "sha256-ExwcFJVqQF/RTUyv1FvOCnlB+9Z7uhi/5UUjW7WcXTk=";

  meta = with lib; {
    description = "simplified find command made with rust";
    homepage = "https://github.com/LyonSyonII/hunt-rs";
    license = licenses.mit;
    mainProgram = "hunt";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
