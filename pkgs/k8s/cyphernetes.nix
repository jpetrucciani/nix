# [cyphernetes](https://github.com/AvitalTamir/cyphernetes) is an alternative k8s query language
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "cyphernetes";
  version = "0.14.0";

  src = fetchFromGitHub {
    owner = "AvitalTamir";
    repo = "cyphernetes";
    rev = "v${version}";
    hash = "sha256-rxZWI+2eWMNTjphxS+lsxAoZUXD8wWF1pfe6hLBxtuM=";
  };

  vendorHash = "sha256-DRzYgpHShZn+17R1Jj/arwAP5lyTpWelmwloUxT3n5Y=";

  ldflags = [ "-s" "-w" ];

  meta = {
    description = "A Kubernetes Query Language";
    homepage = "https://github.com/AvitalTamir/cyphernetes";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "cyphernetes";
  };
}
