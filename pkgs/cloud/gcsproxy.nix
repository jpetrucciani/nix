{ lib, buildGo120Module, fetchFromGitHub, ... }:
buildGo120Module rec {
  pname = "gcsproxy";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "daichirata";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-lMOGaNkNCdWJbNU24OfHJIafRbK7dSi8B3s5mP9icgg=";
  };

  vendorHash = "sha256-Wsa9zPFE4q9yBxflovzkrzn0Jq1a4zlxc5jJOsl7HDQ=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "Reverse proxy for Google Cloud Storage";
    mainProgram = "gcsproxy";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
