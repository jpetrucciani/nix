# [katafygio](https://github.com/bpineau/katafygio) is a tool to dump k8s objects to files
{ lib, buildGo122Module, fetchFromGitHub }:
buildGo122Module rec {
  pname = "katafygio";
  version = "0.8.3";

  src = fetchFromGitHub {
    owner = "bpineau";
    repo = "katafygio";
    rev = "v${version}";
    sha256 = "sha256-0UjhkQeR+97OZRug85e/mfri5ZZW3KaNJyCHT+9/7s4=";
  };

  vendorHash = "sha256-641dqcjPXq+iLx8JqqOzk9JsKnmohqIWBeVxT1lUNWU=";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/bpineau/katafygio/cmd.version=${version}"
  ];

  meta = with lib; {
    description = "Dump, or continuously backup Kubernetes objects as yaml files in git";
    homepage = "https://github.com/bpineau/katafygio";
    license = licenses.mit;
    mainProgram = "katafygio";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
