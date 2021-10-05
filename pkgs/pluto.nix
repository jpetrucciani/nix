{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "5.0.1";
  pname = "pluto";

  src = fetchFromGitHub {
    owner = "FairwindsOps";
    repo = pname;
    rev = "v${version}";
    sha256 = "0qplh8khp0kvavcvqna05hpyz3lyiz7hffgd6fa7qqrrbcs18flp";
  };

  # vendorSha256 = lib.fakeSha256;
  vendorSha256 = "qU4fkvLurXBEJB24AkiY4MJEeXqmwY3S9qTGGsrtjvA=";

  meta = with lib; {
    homepage = "https://github.com/${src.owner}/${src.repo}";
    description = "A cli tool to help discover deprecated apiVersions in Kubernetes";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
