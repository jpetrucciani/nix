# [github_exporter](https://github.com/promhippie/github_exporter) is a prometheus exporter for github
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "github-exporter";
  version = "3.1.2";

  src = fetchFromGitHub {
    owner = "promhippie";
    repo = "github_exporter";
    rev = "v${version}";
    hash = "sha256-9Btt5uPbU7qX3vZYoF7vLOkJSonMLGVnGebs/wTXLP0=";
  };

  vendorHash = "sha256-umBE1ybTNH4RZV/VcRHFW52sMJzCudU4IsTVdtmTOdM=";

  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "Prometheus exporter for GitHub";
    homepage = "https://github.com/promhippie/github_exporter";
    changelog = "https://github.com/promhippie/github_exporter/blob/${src.rev}/CHANGELOG.md";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "github-exporter";
  };
}
