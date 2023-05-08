{ lib, buildGo120Module, fetchFromGitHub, installShellFiles }:
buildGo120Module rec {
  pname = "ov";
  version = "0.21.0";

  src = fetchFromGitHub {
    owner = "noborus";
    repo = "ov";
    rev = "v${version}";
    sha256 = "sha256-gH7DBk40wB2wnYZX4BNRiUDfnEYYRxHTNh/w4pHbZpw=";
  };

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${version}"
  ];

  vendorHash = "sha256-9zzJJcq6XrlbLXnpYoSlLMhY6O6QmdNdskXWHkC1u2I=";

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion --cmd ov \
      --bash <($out/bin/ov --completion bash) \
      --fish <($out/bin/ov --completion fish) \
      --zsh  <($out/bin/ov --completion zsh)
  '';

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "Feature-rich terminal-based text viewer";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
