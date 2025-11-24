# [rdpgw](https://github.com/bolkedebruin/rdpgw) is a Remote Desktop Gateway in Go for deploying on Linux/BSD/Kubernetes
{ lib
, buildGoModule
, fetchFromGitHub
, pam
}:
buildGoModule {
  pname = "rdpgw";
  version = "2.2.0";

  src = fetchFromGitHub {
    # owner = "bolkedebruin";
    owner = "jpetrucciani";
    repo = "rdpgw";
    rev = "2adacfdb9d6baa32adddc1acbc468b9653384a85";
    # rev = "v${version}";
    hash = "sha256-gEPAlGcjeIZ0d9nFRBFpybXt8IHlwMkT+mwD4P1C+Dc=";
  };

  vendorHash = "sha256-KH3c8IAFkXCDLleRTiTnXx+q6LpLl6oTswwmLZPUUSI=";

  buildInputs = [ pam ];

  ldflags = [ "-s" "-w" ];

  meta = {
    description = "Remote Desktop Gateway in Go for deploying on Linux/BSD/Kubernetes";
    homepage = "https://github.com/bolkedebruin/rdpgw";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "rdpgw";
  };
}
