{ lib, buildGo122Module, fetchFromGitHub }:
buildGo122Module rec {
  pname = "goaws";
  version = "0.4.2";

  src = fetchFromGitHub {
    owner = "Admiral-Piett";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-lnDmLBJS7DE0BclwNzuS3zWdZsUCWEIsd0hubgkn5As=";
  };

  vendorHash = "sha256-VqRRCQKtqhRtxG8uJrf332vXr1Lo0ivu8UNWf6y/K2s=";

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
