{ lib, fetchFromGitHub, rustPlatform, ... }:
let
  pname = "dirdiff";
  version = "0.2.0";
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = pname;
    rev = "028bc54b5b6aada3b291ffe5c027b113e5ed4d10";
    sha256 = "sha256-YDPYH/qaJkD02/pQdVuiLzNwX+CLYGmMPJrTlYgOqgQ=";
  };

  cargoHash = "sha256-45aq79k2dBkW07iCivkMlFl3Hyd3SAls3UgrCA100u0=";

  meta = with lib; {
    description = "Efficiently compute the differences between two directories";
    homepage = "https://github.com/ocamlpro/dirdiff";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
