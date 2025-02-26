# [supabase-cli](https://github.com/supabase/cli) is the main CLI interface for [supabase](https://supabase.com)
{ lib
, buildGoModule
, installShellFiles
, fetchFromGitHub
, testers
, supabase-cli
}:

buildGoModule rec {
  pname = "supabase-cli-stable";
  version = "2.15.8";

  src = fetchFromGitHub {
    owner = "supabase";
    repo = "cli";
    rev = "v${version}";
    hash = "sha256-ha3wY2uzC93LlO6a/sgHg2uvU+0+PD/982bzIo0rcBE=";
  };

  vendorHash = "sha256-1IVdsW8vdu2c8ht6d/+yAiHnu5Cwe46QCgUA9F8rnEM=";

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/supabase/cli/internal/utils.Version=${version}"
  ];

  doCheck = false; # tests are trying to connect to localhost

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    rm $out/bin/{docs,listdep}
    mv $out/bin/{cli,supabase}

    installShellCompletion --cmd supabase \
      --bash <($out/bin/supabase completion bash) \
      --fish <($out/bin/supabase completion fish) \
      --zsh <($out/bin/supabase completion zsh)
  '';

  passthru = {
    tests.version = testers.testVersion {
      package = supabase-cli;
    };
  };

  meta = with lib; {
    description = "Supabase CLI. Manage postgres migrations, run Supabase locally, deploy edge functions. Postgres backups. Generating types from your database schema";
    homepage = "https://github.com/supabase/cli";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "supabase";
  };
}
