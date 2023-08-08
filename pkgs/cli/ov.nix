{ lib, buildGo120Module, fetchFromGitHub, installShellFiles }:
buildGo120Module rec {
  pname = "ov";
  version = "0.30.0";

  src = fetchFromGitHub {
    owner = "noborus";
    repo = "ov";
    rev = "v${version}";
    sha256 = "sha256-xTnUTtMm986MnQEKgExWfABU8E8C+ZiRZvOpg3FY5cY=";
  };

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${version}"
  ];

  vendorHash = "sha256-bQREazHu0SQrMKyNPtUvzeKR/zb0FJOLpHBwHml43Hs=";

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
    mainProgram = "ov";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
