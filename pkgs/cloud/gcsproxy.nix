# [gcsproxy](https://github.com/daichirata/gcsproxy/) is a reverse proxy for google cloud storage
{ lib, buildGo124Module, fetchFromGitHub, ... }:
buildGo124Module rec {
  pname = "gcsproxy";
  version = "0.4.1";

  src = fetchFromGitHub {
    owner = "daichirata";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-ZKbqNM7qN9YAqmzZHgDIy+eR4+ZULXuJgXI/Q1m3UGI=";
  };

  vendorHash = "sha256-Wsa9zPFE4q9yBxflovzkrzn0Jq1a4zlxc5jJOsl7HDQ=";

  meta = with lib; {
    description = "Reverse proxy for Google Cloud Storage";
    homepage = "https://github.com/daichirata/gcsproxy/";
    mainProgram = "gcsproxy";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
