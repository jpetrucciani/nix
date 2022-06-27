{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "4.3.3";
  pname = "goldilocks";

  src = fetchFromGitHub {
    owner = "FairwindsOps";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-M6SRXkr9hPXKwO+aQ1xYj5NUrRRo4g4vMi19XwINDXw=";
  };

  vendorSha256 = "sha256-pz+gjNvXsaFGLYWCPaa5zOc2TUovNaTFrvT/dW49KuQ=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "Get your resource requests 'Just Right'";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
