{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, installShellFiles
, git
}:

rustPlatform.buildRustPackage rec {
  pname = "harmonia";
  version = "0.0.3";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "harmonia";
    rev = "v${version}";
    hash = "sha256-6Akn9+nPMcmoAz1OkbBM14wtz2XjJNDHjED/IXqiiIM=";
  };

  cargoHash = "sha256-FFR3VFQeMr+AjYGs8glTaR8K2VbT6CLVE5Zb32yhhnk=";

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
