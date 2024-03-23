{ lib, buildGo122Module, fetchFromGitHub, installShellFiles }:
buildGo122Module rec {
  pname = "poglets";
  version = "0.0.3";
  commit = "0e96c5f5887cd317cd92e6e51eb366929cee3ed1";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = pname;
    rev = version;
    hash = "sha256-owWLviFu/Y+365XZEw7vjmJMmz8wAYMkvGonVJDJ9rU=";
  };

  vendorHash = "sha256-Hjdv2Fvl1S52CDs4TAR3Yt9pEFUIvs5N5sVhZY+Edzo=";

  nativeBuildInputs = [ installShellFiles ];

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${version}"
    "-X main.GitCommit=${commit}"
  ];

  postInstall = ''
    installShellCompletion --cmd poglets \
      --bash <($out/bin/poglets completion bash) \
      --fish <($out/bin/poglets completion fish) \
      --zsh  <($out/bin/poglets completion zsh)
  '';

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "";
    license = licenses.mit;
    mainProgram = "poglets";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
