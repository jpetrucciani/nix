# [epimetheus](https://github.com/jpetrucciani/epimetheus) is a swiss army knife prometheus exporter capable of watching json/csv/yaml files and providing prometheus metrics
{ lib
, rustPlatform
, fetchFromGitHub
, stdenv
, darwin
}:
let
  osSpecific =
    if stdenv.isDarwin then
      (with darwin.apple_sdk.frameworks; [
        Security
        SystemConfiguration
      ]) else [ ];
in
rustPlatform.buildRustPackage rec {
  pname = "epimetheus";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "epimetheus";
    rev = version;
    hash = "sha256-Olgy944mPv0Lq2KfyyBMqqkyHu2tW18OQNz/I6CPI0c=";
  };

  cargoHash = "sha256-3WtVezwva8sJF7OQt599ATc74BVqKojmD0hWtEpSEu8=";

  buildInputs = osSpecific;

  meta = with lib; {
    description = "A swiss army knife prometheus exporter capable of watching json/csv/yaml files and providing prometheus metrics";
    homepage = "https://github.com/jpetrucciani/epimetheus";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "epimetheus";
  };
}
