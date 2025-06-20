# [aws-secretsmanager-agent](https://github.com/aws/aws-secretsmanager-agent) is a local HTTP service that you can install and use in your compute environments to read secrets from Secrets Manager and cache them in memory
{ lib
, rustPlatform
, fetchFromGitHub
, stdenv
, darwin
, cacert
}:
rustPlatform.buildRustPackage rec {
  pname = "aws-secretsmanager-agent";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "aws";
    repo = "aws-secretsmanager-agent";
    rev = "refs/tags/v${version}";
    hash = "sha256-/+284hG4wVSaRaRcUJ00BYuVyB8YMgIKGK+DrP6V6rQ=";
  };

  cargoHash = "sha256-9yzRGioTICwPEHzUUb8/UGFfKSWOU4Fqa5YZ89Zc/HY=";

  buildInputs = [ cacert ];

  meta = with lib; {
    description = "The AWS Secrets Manager Agent is a local HTTP service that you can install and use in your compute environments to read secrets from Secrets Manager and cache them in memory";
    homepage = "https://github.com/aws/aws-secretsmanager-agent";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "aws-secretsmanager-agent";
  };
}
