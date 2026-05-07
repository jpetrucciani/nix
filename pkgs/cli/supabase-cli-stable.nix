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
  version = "2.98.2";

  src = fetchFromGitHub {
    owner = "supabase";
    repo = "cli";
    rev = "v${version}";
    hash = "sha256-ZiptplUqebmId7noXuVXu9G5y1SW8+FGV6WqPH8R3Cw=";
  };

  vendorHash = "sha256-2BIP500MgABRzsG13UaUVv8KKtA0dPM0U10Uk/rfVQY=";

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

  excludedPackages = [ "pkg" "fsevents" ];

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
