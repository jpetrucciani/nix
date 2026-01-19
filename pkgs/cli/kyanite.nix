# [kyanite](https://github.com/gemologic/kyanite) is a high-performance parallel command execution tool for Rust, inspired by GNU parallel and xargs
{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "kyanite";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "gemologic";
    repo = "kyanite";
    rev = "v${version}";
    hash = "sha256-1wkF5JH9VFiwvhcpijMEia3m4SfK23E7tIobaa3D3/8=";
  };

  cargoHash = "sha256-BA4y8ATYuBK5Koey6+TCn9ygNlFQmS0AY1DKs61FMTc=";

  meta = {
    description = "high-performance parallel command execution tool for Rust, inspired by GNU parallel and xargs";
    homepage = "https://github.com/gemologic/kyanite";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "kyanite";
  };
}
