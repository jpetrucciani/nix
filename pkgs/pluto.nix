{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "5.7.0";
  pname = "pluto";

  src = fetchFromGitHub {
    owner = "FairwindsOps";
    repo = pname;
    rev = "v${version}";
    sha256 = "1mn8v6c20cqa3gzpkzjabgljyqr0d660945ym5x8z5paj313yzzw";
  };

  vendorSha256 = "sha256-jPVlHyKZ1ygF08OypXOMzHBfb2z5mhg5B8zJmAcQbLk=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "A cli tool to help discover deprecated apiVersions in Kubernetes";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
