{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "4.3.2";
  pname = "goldilocks";

  src = fetchFromGitHub {
    owner = "FairwindsOps";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-GdO03L/cG5yoYSYXfGkeSnbZxCKx9Qi31PQGrbrAbJQ=";
  };

  vendorSha256 = "sha256-zpx3lcc3Hp622u6wiP3Xa3YUKnNCb5Q19rjPbVHuTFA=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "Get your resource requests 'Just Right'";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
