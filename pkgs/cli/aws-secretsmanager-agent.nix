# [aws-secretsmanager-agent](https://github.com/aws/aws-secretsmanager-agent) is a local HTTP service that you can install and use in your compute environments to read secrets from Secrets Manager and cache them in memory
{ lib
, rustPlatform
, fetchFromGitHub
, cacert
}:
rustPlatform.buildRustPackage rec {
  pname = "aws-secretsmanager-agent";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "aws";
    repo = "aws-secretsmanager-agent";
    rev = "refs/tags/v${version}";
    hash = "sha256-zNqe7TdABaKil2/dtoHHlwVakQqwkhbHXWvYk9YnC6w=";
  };

  cargoHash = "sha256-Y1K+U6y7p5VHvvG4/o+hSGf5DltaT6/lAcULlyCRDuU=";

  buildInputs = [ cacert ];

  meta = with lib; {
    description = "The AWS Secrets Manager Agent is a local HTTP service that you can install and use in your compute environments to read secrets from Secrets Manager and cache them in memory";
    homepage = "https://github.com/aws/aws-secretsmanager-agent";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "aws-secretsmanager-agent";
  };
}
