# [xlsxsql](https://github.com/noborus/xlsxsql) is a cli tool for executing SQL queries on excel files
{ lib
, buildGoModule
, fetchFromGitHub
, installShellFiles
}:

buildGoModule rec {
  pname = "xlsxsql";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "noborus";
    repo = "xlsxsql";
    rev = "v${version}";
    hash = "sha256-T9RqgNq1OA9veLpfC1yEh+tcc+K0jrLdqGqCU5t9JMk=";
  };

  vendorHash = "sha256-lktnHpqk/c1rNHtlHl5lsrMRwOP8rnYJvlJqGqg0mfA=";

  nativeBuildInputs = [ installShellFiles ];

  ldflags = [
    "-s"
    "-w"
    "-X=main.version=${version}"
    "-X=main.revision=${src.rev}"
  ];

  postInstall = ''
    installShellCompletion --cmd xlsxsql \
      --bash <($out/bin/xlsxsql completion bash) \
      --fish <($out/bin/xlsxsql completion fish) \
      --zsh  <($out/bin/xlsxsql completion zsh)
  '';

  meta = with lib; {
    description = "A CLI tool that executes SQL queries on various files including xlsx files and outputs the results to various files";
    homepage = "https://github.com/noborus/xlsxsql";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "xlsxsql";
  };
}
