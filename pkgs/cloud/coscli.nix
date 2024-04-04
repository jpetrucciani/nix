# [coscli](https://github.com/tencentyun/coscli) is a tencent cloud command line tool
{ lib, buildGo122Module, fetchFromGitHub, ... }:
buildGo122Module rec {
  pname = "coscli";
  version = "0.13.0";

  src = fetchFromGitHub {
    owner = "tencentyun";
    repo = pname;
    rev = "v${version}-beta";
    sha256 = "sha256-G9RN07L26g81VA22sB+zG0PFYx6RvU9NuEpL7Hc0bOo=";
  };

  vendorHash = "sha256-B0gUj+10R2zCF2HlqqcVS5uxWv03+DVlETPMledwSho=";

  ldflags = [
    "-s"
    "-w"
  ];

  doCheck = false;

  meta = with lib; {
    description = "tencent cloud command line tool";
    homepage = "https://github.com/tencentyun/coscli";
    license = licenses.asl20;
    mainProgram = "coscli";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
