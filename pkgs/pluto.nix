{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "5.5.2";
  pname = "pluto";

  src = fetchFromGitHub {
    owner = "FairwindsOps";
    repo = pname;
    rev = "v${version}";
    sha256 = "0qplh8khp0kvavcvqna05hpyz3lyiz7hffgd6fa7qqrrbcs18flp";
  };

  vendorSha256 = "sha256-qU4fkvLurXBEJB24AkiY4MJEeXqmwY3S9qTGGsrtjvA=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "A cli tool to help discover deprecated apiVersions in Kubernetes";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
