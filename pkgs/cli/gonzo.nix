# [gonzo](https://github.com/control-theory/gonzo) is the Go based TUI log analysis tool
{ lib
, buildGoModule
, fetchFromGitHub
, installShellFiles
}:

buildGoModule rec {
  pname = "gonzo";
  version = "0.1.5";

  src = fetchFromGitHub {
    owner = "control-theory";
    repo = "gonzo";
    rev = "v${version}";
    hash = "sha256-lB7OTDdJwd+ldWv7ewko/4kO/NP4bhDi+IpZOEL3x9U=";
  };

  vendorHash = "sha256-XKwtq8EF774lHLHtyFzveFa5agJa15CvhsuwwaQdJwU=";

  ldflags = [
    "-s"
    "-w"
    "-X=main.version=${version}"
    "-X=main.commit=${src.rev}"
    "-X=main.buildTime=1970-01-01T00:00:00Z"
  ];

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion --cmd gonzo \
      --bash <($out/bin/gonzo completion bash) \
      --fish <($out/bin/gonzo completion fish) \
      --zsh  <($out/bin/gonzo completion zsh)
  '';

  meta = {
    description = "Gonzo! The Go based TUI log analysis tool";
    homepage = "https://github.com/control-theory/gonzo";
    changelog = "https://github.com/control-theory/gonzo/blob/${src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "gonzo";
  };
}
