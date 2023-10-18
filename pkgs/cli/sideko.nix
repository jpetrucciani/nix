{ lib
, rustPlatform
, fetchFromGitHub
, stdenv
, darwin
}:

rustPlatform.buildRustPackage rec {
  pname = "sideko";
  version = "0.1.4";

  src = fetchFromGitHub {
    owner = "Sideko-Inc";
    repo = "sideko";
    rev = "v${version}";
    hash = "sha256-T9XDDK1acx1OvFiW8UUx2w3jbQv1AezB9DKW7qe7Syw=";
  };

  cargoHash = "sha256-2LDYOCzCOkwrXCrbQqeLKmvduZtN74q9o4q5Ax5dDlI=";

  buildInputs = lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
  ];

  meta = with lib; {
    description = "Generate SDKs for your API";
    homepage = "https://github.com/Sideko-Inc/sideko";
    license = licenses.elastic20;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "sideko";
  };
}
