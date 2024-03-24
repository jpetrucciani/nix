# A fast configurable port scanner with reasonable defaults
{ lib, fetchFromGitHub, rustPlatform }:
let
  pname = "havn";
  version = "0.1.8";
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "mrjackwills";
    repo = pname;
    rev = "refs/tags/v${version}";
    sha256 = "sha256-HAJ4gPS2ubi7Qu+XUh9Z2pNGm3G0NOl3k8GQtMox0MU=";
  };

  cargoHash = "sha256-ueXkZu58YJ5pktHwWIlwtWo4njGHlKXImLyE4eRoSEE=";

  checkFlags = [
    # these tests attempt to bind to local ports
    "--skip=scanner::tests::test_scanner_1000_80_443"
    "--skip=scanner::tests::test_scanner_1000_empty"
    "--skip=scanner::tests::test_scanner_all_80"
    "--skip=scanner::tests::test_scanner_port_80"
    "--skip=terminal::print::tests::test_terminal_monochrome_false"
  ];

  meta = with lib; {
    description = "A fast configurable port scanner with reasonable defaults";
    homepage = "https://github.com/mrjackwills/havn";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
