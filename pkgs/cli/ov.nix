# [ov](https://github.com/noborus/ov) is a Feature-rich terminal-based text viewer.
{ lib, buildGo124Module, fetchFromGitHub, installShellFiles }:
buildGo124Module rec {
  pname = "ov";
  version = "0.32.0";

  src = fetchFromGitHub {
    owner = "noborus";
    repo = "ov";
    rev = "v${version}";
    sha256 = "sha256-mQ1KwElD8RizOT2trHWo4T1QiZ974xwhQCCa5snpnZM=";
  };

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${version}"
  ];

  vendorHash = "sha256-XACdtJdACMKQ5gSJcjGAPNGPFL1Tbt6QOovl15mvFGI=";

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion --cmd ov \
      --bash <($out/bin/ov --completion bash) \
      --fish <($out/bin/ov --completion fish) \
      --zsh  <($out/bin/ov --completion zsh)
  '';

  meta = with lib; {
    description = "Feature-rich terminal-based text viewer";
    homepage = "https://github.com/noborus/ov";
    license = licenses.mit;
    mainProgram = "ov";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
