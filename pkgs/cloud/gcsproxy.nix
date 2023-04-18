{ lib, buildGo120Module, fetchFromGitHub, ... }:
buildGo120Module rec {
  pname = "gcsproxy";
  version = "0.3.2";

  src = fetchFromGitHub {
    owner = "daichirata";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-yeAN2pFgakgqTM4/sq9sgVBJi2zL3qamHsKN3s+ntds=";
  };

  vendorHash = "sha256-Wsa9zPFE4q9yBxflovzkrzn0Jq1a4zlxc5jJOsl7HDQ=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "Reverse proxy for Google Cloud Storage";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
