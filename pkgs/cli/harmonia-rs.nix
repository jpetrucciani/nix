{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, installShellFiles
, git
}:

rustPlatform.buildRustPackage rec {
  pname = "harmonia";
  version = "0.0.2";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "harmonia";
    rev = "v${version}";
    hash = "sha256-w9M7lrcM3hB0v0yKrkGNNNmWF6pQ3r4QOmchN36ss9g=";
  };

  cargoHash = "sha256-wZ0SkuZs1G3tX9+DGsLPbdb3hnRz7fLykNQ/qc5OLH0=";

  nativeBuildInputs = [
    pkg-config
    installShellFiles
  ];

  nativeCheckInputs = [
    git
  ];

  postInstall = ''
    installShellCompletion --cmd harmonia \
      --bash <($out/bin/harmonia completion bash) \
      --fish <($out/bin/harmonia completion fish) \
      --zsh <($out/bin/harmonia completion zsh)
  '';

  meta = {
    description = "a multi-repo orchestration tool";
    homepage = "https://github.com/jpetrucciani/harmonia";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "harmonia";
  };
}
