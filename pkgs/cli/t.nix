# [t](https://github.com/alecthomas/t) is a concise language for manipulating text
{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "t";
  version = "0.0.5";

  src = fetchFromGitHub {
    owner = "alecthomas";
    repo = "t";
    rev = "v${version}";
    hash = "sha256-ZNZc8B0F2z0C5WRoq2YD/dciJNl64ScOA3p4yNOwe9A=";
  };

  cargoHash = "sha256-Vpisck1TMU3iubfA77DSBExEnwtVV/eibcC+qMR0+Y8=";

  meta = {
    description = "T is a concise language for manipulating text, replacing common usage patterns of Unix utilities like grep, sed, cut, awk, sort, and uniq";
    homepage = "https://github.com/alecthomas/t";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "t";
  };
}
