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
  version = "2.33.5";

  src = fetchFromGitHub {
    owner = "supabase";
    repo = "cli";
    rev = "v${version}";
    hash = "sha256-XSCL/7QxvEz1z3V3HnU7WBDzfgcbyPIj7lEnYVmHlpY=";
  };

  vendorHash = "sha256-PGmQT2Dfbso+i3m+viNOsGPXsOpC1umR3lfTSY1s6VI=";

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

  excludedPackages = [ "pkg" ];

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
