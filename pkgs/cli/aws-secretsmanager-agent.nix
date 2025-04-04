# [aws-secretsmanager-agent](https://github.com/aws/aws-secretsmanager-agent) is a local HTTP service that you can install and use in your compute environments to read secrets from Secrets Manager and cache them in memory
{ lib
, rustPlatform
, fetchFromGitHub
, stdenv
, darwin
}:

rustPlatform.buildRustPackage {
  pname = "aws-secretsmanager-agent";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "aws";
    repo = "aws-secretsmanager-agent";
    rev = "705662d8467a2a1f29bc00501a373a758c771dab"; # actual v1.0.0 tag doesn't seem to build - but this commit is the initial commit of the OSS repo
    hash = "sha256-8wfA4e+PhDUqd9sFIoWIqL3nEehoK27Z8rD+E28Rqb8=";
  };

  cargoHash = "sha256-FyacZx1s8ApnePkU8q1P0bMXy+WT51yfpI5kM6YIQHA=";

  buildInputs = lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
  ];

  meta = with lib; {
    description = "The AWS Secrets Manager Agent is a local HTTP service that you can install and use in your compute environments to read secrets from Secrets Manager and cache them in memory";
    homepage = "https://github.com/aws/aws-secretsmanager-agent";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "aws-secretsmanager-agent";
  };
}
