# [epimetheus](https://github.com/jpetrucciani/epimetheus) is a swiss army knife prometheus exporter capable of watching json/csv/yaml files and providing prometheus metrics
{ lib
, rustPlatform
, fetchFromGitHub
, darwin
}:
rustPlatform.buildRustPackage rec {
  pname = "epimetheus";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "epimetheus";
    rev = version;
    hash = "sha256-Olgy944mPv0Lq2KfyyBMqqkyHu2tW18OQNz/I6CPI0c=";
  };

  cargoHash = "sha256-N3LPYiQkxzbNpHUo4AKBP5UFA7FPya4tYvV4OM8uahA=";

  meta = with lib; {
    description = "A swiss army knife prometheus exporter capable of watching json/csv/yaml files and providing prometheus metrics";
    homepage = "https://github.com/jpetrucciani/epimetheus";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "epimetheus";
  };
}
