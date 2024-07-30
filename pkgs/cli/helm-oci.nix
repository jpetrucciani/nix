# [helm-oci](https://github.com/ikimpriv/helm-oci) is a command line tool that is useful for listing helm charts in oci repos
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "helm-oci";
  version = "0.1";

  src = fetchFromGitHub {
    owner = "ikimpriv";
    repo = "helm-oci";
    rev = "v${version}";
    hash = "sha256-gfIT7HtgILK6hizGJvRckEH7k86bobGS+ViHhADNteA=";
  };

  vendorHash = "sha256-K9S7qVVI/hQ0FGfuj5CN1rxilb7zeUTtM6Lb1dwfLUc=";

  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "Command-line tool that helps in listing and deleting helm charts/tags in OCI repositories";
    homepage = "https://github.com/ikimpriv/helm-oci";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "helm-oci";
  };
}
