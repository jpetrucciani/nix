# [kor](https://github.com/yonahd/kor) is a tool to find unused k8s resources
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "kor";
  version = "0.3.6";

  src = fetchFromGitHub {
    owner = "yonahd";
    repo = "kor";
    rev = "v${version}";
    hash = "sha256-Q2VUc91ecBRr/m9DGYWwuSsH2prB+EKmBoQrekgPvTE=";
  };

  vendorHash = "sha256-DRbwM6fKTIlefD0rUmNLlUXrK+t3vNCl4rxHF7m8W10=";

  doCheck = false;
  CGO_ENABLED = 0;
  ldflags = [
    "-X=github.com/yonahd/kor/pkg/utils.Version=${version}"
  ];

  meta = with lib; {
    description = "A Golang Tool to discover unused Kubernetes Resources";
    homepage = "https://github.com/yonahd/kor";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "kor";
  };
}
