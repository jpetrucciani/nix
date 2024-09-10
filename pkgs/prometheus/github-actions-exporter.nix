# [github-actions-exporter](https://github.com/Labbs/github-actions-exporter) is a github-actions-exporter for prometheus
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "github-actions-exporter";
  version = "1.9.0";

  src = fetchFromGitHub {
    owner = "Labbs";
    repo = "github-actions-exporter";
    rev = "v${version}";
    hash = "sha256-3KtNlreCPZFonIMJgi+OQaYV6EUTBFRPhuzyO1uvVAQ=";
  };

  vendorHash = "sha256-5FHKbj7lL0Ki2IPm46yzF8KIPUmQYq4Rvk2u1riNtbM=";

  ldflags = [ "-s" "-w" ];

  meta = {
    description = "Github-actions-exporter for prometheus";
    homepage = "https://github.com/Labbs/github-actions-exporter";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "github-actions-exporter";
  };
}
