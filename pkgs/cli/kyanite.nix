# [kyanite](https://github.com/gemologic/kyanite) is a high-performance parallel command execution tool for Rust, inspired by GNU parallel and xargs
{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "kyanite";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "gemologic";
    repo = "kyanite";
    rev = "v${version}";
    hash = "sha256-V07ph6p6LIyGSD3u7952S+q9MEnUfkyOsBFCnRyCrX8=";
  };

  cargoHash = "sha256-xCekY3ID5BixBsgXSZJ7/OSqZ71iaK4YJU98TXvRzZI=";

  meta = {
    description = "high-performance parallel command execution tool for Rust, inspired by GNU parallel and xargs";
    homepage = "https://github.com/gemologic/kyanite";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "kyanite";
  };
}
