{ lib, buildGo120Module, fetchFromGitHub }:
buildGo120Module rec {
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
    inherit (src.meta) homepage;
    description = "on-demand, scaleable source of container resource metrics for K8s";
    license = licenses.asl20;
    mainProgram = "murre";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
