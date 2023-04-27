{ lib, buildGo120Module, fetchFromGitHub, clangStdenv }:
(buildGo120Module.override { stdenv = clangStdenv; }) rec {
  pname = "bigquery-emulator";
  version = "0.2.12";
  commit = "f21fa982972a8be6444c23459a88df58de7b14b4";

  src = fetchFromGitHub {
    owner = "goccy";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-mGR3s7OHuiMN1LqoWKRkJoXmZkqL7Ye9zJkDC4OFtus=";
  };

  vendorHash = "sha256-NJktyKDyByAWLAc/oayOSQxohKPcxAHiW2ynM77cCOY=";

  CGO_ENABLED = 1;

  nativeBuildInputs = [ ];
  subPackages = [
    "./cmd/bigquery-emulator"
  ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
    "-X main.revision=${commit}"
    "-linkmode external"
  ];

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "BigQuery emulator server implemented in Go";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
