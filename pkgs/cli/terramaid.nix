# [terramaid](https://github.com/RoseSecurity/Terramaid) is a utility for generating Mermaid diagrams from Terraform configurations
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "terramaid";
  version = "1.8.0";

  src = fetchFromGitHub {
    owner = "RoseSecurity";
    repo = "Terramaid";
    rev = "v${version}";
    hash = "sha256-EyLpNVkHmwjT/I3GDwHDQrceAtTh49gmIciR4taahV8=";
  };

  vendorHash = "sha256-I8bLPKqyGrsUpDFtgt3DPRWit8L/NLIdCWCo3t2tiHo=";

  ldflags = [
    "-s"
    "-w"
    "-X=main.version=${version}"
  ];

  meta = with lib; {
    description = "A utility for generating Mermaid diagrams from Terraform configurations";
    homepage = "https://github.com/RoseSecurity/Terramaid";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "terramaid";
  };
}
