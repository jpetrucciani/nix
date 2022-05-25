{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.3.0";
  pname = "kube-linter";

  src = fetchFromGitHub {
    owner = "stackrox";
    repo = "kube-linter";
    rev = version;
    sha256 = "sha256-ZqnD9zsh+r1RL34o1nAkvO1saKe721ZJ2+DgBjmsH58=";
  };

  vendorSha256 = "sha256-tm1+2jsktNrw8S7peJz7w8k3+JwAYUgKfKWuQ8zIfvk=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description =
      "static analysis tool that checks Kubernetes YAML files and Helm charts to ensure the applications represented in them adhere to best practices";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
