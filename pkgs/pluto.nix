{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "5.9.0";
  pname = "pluto";

  src = fetchFromGitHub {
    owner = "FairwindsOps";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-Rwilj6+HEAriYO+zlErSN0dDMZIKFq/z5oSoSlCLZFg=";
  };

  vendorSha256 = "sha256-l2EO1L64ldhinGRGFY13A2ftT/ho6fYrA0dFG6jUX2Q=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "A cli tool to help discover deprecated apiVersions in Kubernetes";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
