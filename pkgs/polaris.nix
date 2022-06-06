{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "6.0.0";
  pname = "polaris";

  src = fetchFromGitHub {
    owner = "FairwindsOps";
    repo = pname;
    rev = version;
    sha256 = "sha256-Q0jDySEmzCrjCmc4H9ap/AmopNtdAq4zOAh/6LZ/dFo=";
  };

  vendorSha256 = "sha256-SC86x2vE1TNZBxDNxyxjOPILdQbGAfSz5lmaC9qCkoE=";
  doCheck = false;

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "Validation of best practices in your Kubernetes clusters";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
