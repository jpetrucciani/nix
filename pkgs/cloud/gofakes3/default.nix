# [gofakes3](https://github.com/johannesboyne/gofakes3) is a fake s3 server
{ lib, buildGoLatestModule, fetchFromGitHub }:
buildGoLatestModule rec {
  pname = "gofakes3";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "johannesboyne";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-DMsLi28x3Mki5PJEsFU6S9hJ6Z+kL/okjM0GgK/QIUI=";
  };

  ldflags = [
    "-s"
    "-w"
  ];

  vendorHash = "sha256-EoTucmFsvNH2rFsqAzjrwH9PJ2JonC3kwASvaUZ7yuI=";

  patches = [ ./gofakes3-bolt-owned-reads.patch ];
  doCheck = true;

  meta = with lib; {
    description = "A simple fake AWS S3 object storage (used for local test-runs against AWS S3 APIs)";
    homepage = "https://github.com/johannesboyne/gofakes3";
    mainProgram = "gofakes3";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
