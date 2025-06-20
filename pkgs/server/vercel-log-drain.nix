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
    rev = "04d002ce54dba769316f649185468de4cf1f7d81";
    hash = "sha256-NkSU8tCuHdS6UXyeSuYjLMDLC7aARon+bfERWdkQz9I=";
  };

  cargoHash = "sha256-tbywC60KrIC69uvUjMWzs6ut0TmouAhEY1qsrRgmkOM=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [ openssl ];

  meta = with lib; {
    description = "A simple log-drain you can deploy to export log messages from Vercel to one or more outputs";
    homepage = "https://github.com/dacbd/vercel-log-drain";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "vercel-log-drain";
  };
}
