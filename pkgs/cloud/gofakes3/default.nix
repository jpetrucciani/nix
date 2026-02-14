# [gofakes3](https://github.com/johannesboyne/gofakes3) is a fake s3 server
{ lib, buildGo125Module, fetchFromGitHub }:
buildGo125Module rec {
  pname = "gofakes3";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "johannesboyne";
    repo = pname;
    rev = "4c385a1f6a730dfb271fc0530400ed8c4d6a1eb8"; # this contains our patch! but is not yet released
    # rev = "refs/tags/${version}";
    hash = "sha256-JaFQBgQlJoo9PZvelPxIF3yeBfRTvC1uVo3Y7HPmBJI=";
  };

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
