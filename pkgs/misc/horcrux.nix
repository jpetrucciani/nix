{ lib, buildGo122Module, fetchFromGitHub }:
buildGo122Module rec {
  pname = "horcrux";
  version = "0.3";

  src = fetchFromGitHub {
    owner = "jesseduffield";
    repo = "horcrux";
    rev = "v${version}";
    sha256 = "sha256-F8zGdjGKVuL/y763a1ZqcdmziGx9PfzXU81RaN7nL+Q=";
  };

  vendorHash = null;

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "Split your file into encrypted fragments so that you don't need to remember a passcode";
    license = licenses.mit;
    mainProgram = "horcrux";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
