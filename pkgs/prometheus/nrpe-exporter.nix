# [nrpe-exporter](https://github.com/canonical/nrpe_exporter) is a Prometheus exporter for generating metrics from commands executed by a running NRPE daemon
{ lib
, buildGoModule
, fetchFromGitHub
, pkg-config
, openssl_1_1
}:

buildGoModule rec {
  pname = "nrpe-exporter";
  version = "0.2.6";

  src = fetchFromGitHub {
    owner = "canonical";
    repo = "nrpe_exporter";
    rev = version;
    hash = "sha256-vy0D44Q0syZYPuAuP34ptg84Gfe8c9cNZZX2TjofKlg=";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl_1_1
  ];

  vendorHash = null;

  ldflags = [ "-s" "-w" ];

  meta = {
    description = "A Prometheus exporter for generating metrics from commands executed by a running NRPE daemon";
    homepage = "https://github.com/canonical/nrpe_exporter";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "nrpe-exporter";
  };
}
