{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.8.3";
  pname = "katafygio";

  src = fetchFromGitHub {
    owner = "bpineau";
    repo = "katafygio";
    rev = "v${version}";
    sha256 = "1kpfgzplz1r04y6sdp2njvjy5ylrpybz780vcp7dxywi0y8y2j6i";
  };

  # vendorSha256 = lib.fakeSha256;
  vendorSha256 = "641dqcjPXq+iLx8JqqOzk9JsKnmohqIWBeVxT1lUNWU=";

  meta = with lib; {
    homepage = "https://github.com/${src.owner}/${src.repo}";
    description = "Dump, or continuously backup Kubernetes objects as yaml files in git";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
