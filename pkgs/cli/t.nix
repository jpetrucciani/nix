# [t](https://github.com/alecthomas/t) is a concise language for manipulating text
{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "t";
  version = "0.0.4";

  src = fetchFromGitHub {
    owner = "alecthomas";
    repo = "t";
    rev = "v${version}";
    hash = "sha256-qbNJhyupjkMim9L5U9J3SWeA1olM1Cd+fwldzyGyHZc=";
  };

  cargoHash = "sha256-Vpisck1TMU3iubfA77DSBExEnwtVV/eibcC+qMR0+Y8=";

  meta = {
    description = "T is a concise language for manipulating text, replacing common usage patterns of Unix utilities like grep, sed, cut, awk, sort, and uniq";
    homepage = "https://github.com/alecthomas/t";
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "t";
  };
}
