# [murre](https://github.com/groundcover-com/murre) is an on-demand scaleable source of container resource metrics for k8s
{ lib, buildGo122Module, fetchFromGitHub }:
buildGo122Module rec {
  pname = "murre";
  version = "0.0.4";

  src = fetchFromGitHub {
    owner = "groundcover-com";
    repo = "murre";
    rev = "v${version}";
    sha256 = "sha256-WHIO8KZ7bm02eT2qdwpyXQf0VAV8W5M5mUks4OxSZMo=";
  };

  vendorHash = "sha256-qKEeRndRTNOD97E4aNQuKzk4wzH55sjW6MTnrF+mG5E=";

  ldflags = [
    "-s"
    "-w"
  ];

  meta = with lib; {
    description = "on-demand, scaleable source of container resource metrics for K8s";
    homepage = "https://github.com/groundcover-com/murre";
    license = licenses.asl20;
    mainProgram = "murre";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
