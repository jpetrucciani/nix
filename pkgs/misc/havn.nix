# A fast configurable port scanner with reasonable defaults
{ lib, fetchFromGitHub, rustPlatform }:
let
  pname = "havn";
  version = "0.1.0";
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "mrjackwills";
    repo = pname;
    rev = "refs/tags/v${version}";
    sha256 = "sha256-zuqYYLmZOTs9MmowEz3J3og8Uu3ibbsRyuQBE9e+A5I=";
  };

  cargoHash = "sha256-5OVmtweweRaUuFjWhy60OrdtxnS7hqTnIgSO/NDxR2s=";

  checkFlags = [
    # these tests attempt to bind to local ports
    "--skip=scanner::tests::test_scanner_1000_80_443"
    "--skip=scanner::tests::test_scanner_1000_empty"
    "--skip=scanner::tests::test_scanner_all_80"
    "--skip=scanner::tests::test_scanner_port_80"
  ];

  meta = with lib; {
    description = "A fast configurable port scanner with reasonable defaults";
    homepage = "https://github.com/mrjackwills/havn";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
