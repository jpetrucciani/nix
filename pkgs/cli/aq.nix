{ lib
, rustPlatform
, fetchFromGitHub
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "aq";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "aq";
    tag = "v${finalAttrs.version}";
    hash = "sha256-N54wR+Bgf72FCJepvb6spiDG3+i/JMLxUyAuE3rySeM=";
  };

  cargoHash = "sha256-ZamSDgRH9Rp+2/e7rN73yv5tUq1UbLdJkpBPJaruXII=";

  meta = {
    description = "Multi-format data processing tool";
    homepage = "https://github.com/jpetrucciani/aq";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "aq";
  };
})
