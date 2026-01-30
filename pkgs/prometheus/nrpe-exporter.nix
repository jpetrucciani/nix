# [nrpe-exporter](https://github.com/canonical/nrpe_exporter) is a Prometheus exporter for generating metrics from commands executed by a running NRPE daemon
{ lib
, buildGoModule
, fetchFromGitHub
, pkg-config
, openssl_3
}:

buildGoModule {
  pname = "nrpe-exporter";
  version = "0.2.6";

  src = fetchFromGitHub {
    # owner = "canonical";
    owner = "jpetrucciani";
    repo = "nrpe_exporter";
    rev = "5671dd3f048cd82e0b6e06908265178151dbf4ec"; # openssl3 support
    hash = "sha256-1TTIvUme0+hQMFa+r9XynaPYyNFddOYep9BabqP2Zps=";
    # hash = "sha256-vy0D44Q0syZYPuAuP34ptg84Gfe8c9cNZZX2TjofKlg=";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl_3
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
