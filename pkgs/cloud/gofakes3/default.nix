# [gofakes3](https://github.com/johannesboyne/gofakes3) is a fake s3 server
{ lib, buildGo125Module, fetchFromGitHub }:
buildGo125Module rec {
  pname = "gofakes3";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "johannesboyne";
    repo = pname;
    rev = "refs/tags/${version}";
    hash = "sha256-eEhshcxMDTFagAeOKYox4K/c93Sd2SvIMaz7kwfQArU=";
  };

  patches = [ ./cors.patch ];

  ldflags = [
    "-s"
    "-w"
  ];

  vendorHash = "sha256-N3ikr8vXYwgm5Q8POM+JV7hxerTqqvPqInE+A3pJDSw=";

  meta = with lib; {
    description = "A simple fake AWS S3 object storage (used for local test-runs against AWS S3 APIs)";
    homepage = "https://github.com/johannesboyne/gofakes3";
    mainProgram = "gofakes3";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
