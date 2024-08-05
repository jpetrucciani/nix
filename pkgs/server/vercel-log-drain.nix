# [vercel-log-drain](https://github.com/dacbd/vercel-log-drain) is a log-drain for vercel that supports multiple drivers to ship logs out to various sources
{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, openssl
, stdenv
, darwin
}:

rustPlatform.buildRustPackage {
  pname = "vercel-log-drain";
  version = "0.0.3";

  src = fetchFromGitHub {
    owner = "dacbd";
    repo = "vercel-log-drain";
    rev = "df4ddace599e9a8c2ac57c27cbb9e39e0c7c52ee";
    hash = "sha256-AmKYPmJ5GCbLu+LB3uObagHjIg2ahsg6kmBWLVF3ACw=";
  };

  cargoHash = "sha256-v/GxeBmR6qhUna3PjZhi9wAEwdmC1t7m6ysfNJ/pfyU=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
  ];

  meta = with lib; {
    description = "A simple log-drain you can deploy to export log messages from Vercel to AWS Cloudwatch";
    homepage = "https://github.com/dacbd/vercel-log-drain";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "vercel-log-drain";
  };
}
