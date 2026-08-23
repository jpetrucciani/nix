{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, installShellFiles
, git
}:

rustPlatform.buildRustPackage rec {
  pname = "harmonia";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "harmonia";
    rev = "v${version}";
    hash = "sha256-pUDDgldKIpXaJ/RRSspPJ1LIplUDGeg2K1FbzCMBXKQ=";
  };

  cargoHash = "sha256-nLw0b9ywfo7ygACMMPlGuRRWozJvlbfGmQXQC/IfY8A=";

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
