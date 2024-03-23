final: prev:
with prev;
rec {
  haproxy-pin = { version, sha256 }: haproxy.overrideAttrs (attrs: rec {
    inherit version;
    src = fetchurl {
      inherit sha256;
      url = "https://www.haproxy.org/download/${lib.versions.majorMinor version}/src/${attrs.pname}-${version}.tar.gz";
    };
  });

  haproxy-2-2-25 = haproxy-pin {
    version = "2.2.25";
    sha256 = "sha256-vrQH6wiyxpfRFaGMANagI/eg+yy5m/+cNMnf2dLFLys=";
  };

  haproxy-2-6-5 = haproxy-pin {
    version = "2.6.5";
    sha256 = "sha256-zp4Z6/zdQ+Ua+KYJDx341RLZct33QvpkimQ7uxkFZgU=";
  };

  bigquery-emulator = prev.callPackage
    ({ lib, buildGo122Module, fetchFromGitHub, clangStdenv }:
      (buildGo122Module.override { stdenv = clangStdenv; }) rec {
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
    )
    { };
}
