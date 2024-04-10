# [goaws](https://github.com/Admiral-Piett/goaws) is a SQS/SNS Clone for Development testing
{ lib, buildGo122Module, fetchFromGitHub }:
buildGo122Module rec {
  pname = "goaws";
  version = "0.4.6";

  src = fetchFromGitHub {
    owner = "Admiral-Piett";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-xxQct7Istl2dMFiXoaNbNtUBaZ9O07crjI3gHhktSbI=";
  };

  vendorHash = "sha256-mq180F0V7BF3GBFgrlME7+5IF6Wfk/xMDWNmIOc6FlU=";

  ldflags = [
    "-s"
    "-w"
  ];

  postInstall = ''
    mv $out/bin/cmd $out/bin/goaws
  '';

  meta = with lib; {
    description = "AWS (SQS/SNS) Clone for Development testing";
    homepage = "https://github.com/Admiral-Piett/goaws";
    mainProgram = "goaws";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
