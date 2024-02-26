{ lib
, buildGoModule
, installShellFiles
, fetchFromGitHub
}:

buildGoModule
rec {
  pname = "supabase-cli-beta";
  version = "1.148.2";

  src = fetchFromGitHub {
    owner = "supabase";
    repo = "cli";
    rev = "v${version}";
    hash = "sha256-s3KwGD4SHQopvopI+Ama/3F90Vi93NsxUWC+bfyrs+E=";
  };

  vendorHash = "sha256-PNAZ+vnbLhuQpXe99wc5c/QEJXYrFoB60Ij9FSDFQxw=";
  proxyVendor = true;

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/supabase/cli/internal/utils.Version=${version}"
  ];

  doCheck = false; # tests are trying to connect to localhost

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    rm $out/bin/{codegen,docs,listdep}
    mv $out/bin/{cli,supabase}

    installShellCompletion --cmd supabase \
      --bash <($out/bin/supabase completion bash) \
      --fish <($out/bin/supabase completion fish) \
      --zsh <($out/bin/supabase completion zsh)
  '';

  meta = with lib; {
    description = "Supabase CLI. Manage postgres migrations, run Supabase locally, deploy edge functions. Postgres backups. Generating types from your database schema";
    homepage = "https://github.com/supabase/cli";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "supabase";
  };
}
