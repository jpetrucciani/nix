{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, sqlite
, installShellFiles
}:

rustPlatform.buildRustPackage rec {
  pname = "mica";
  version = "0.0.4";

  src = fetchFromGitHub {
    owner = "gemologic";
    repo = "mica";
    rev = "v${version}";
    hash = "sha256-4Aleo54km+rLdry1TWRvCqQVThDz2JaVqwrhsZCwKmc=";
  };

  cargoHash = "sha256-MS53DKsqR9C+fqujjz7N/QuQtqtKDavGzad+CPjtTZ8=";

  nativeBuildInputs = [
    pkg-config
    installShellFiles
  ];

  buildInputs = [
    sqlite
  ];

  postInstall = ''
    installShellCompletion --cmd mica \
      --bash <($out/bin/mica completion bash) \
      --fish <($out/bin/mica completion fish) \
      --zsh <($out/bin/mica completion zsh)
  '';

  meta = {
    description = "An experimental TUI for managing nix environments";
    homepage = "https://github.com/gemologic/mica";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "mica";
  };
}
