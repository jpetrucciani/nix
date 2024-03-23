{ lib, buildGo122Module, fetchFromGitHub }:
buildGo122Module rec {
  pname = "terraform-cloud-exporter";
  version = "2.3.0";

  src = fetchFromGitHub {
    owner = "pacoguzman";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-77ns9cBKr/d7gCZRdizuJm+adkk0WNeCVtKMZMLXmQA=";
  };

  vendorHash = "sha256-aw2Hv3utc/sIZC1E3RDsQcmT+FVIhTWkdU0+dB0/4ho=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "Prometheus exporter for Terraform Cloud metrics";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
