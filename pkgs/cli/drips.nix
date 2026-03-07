{ lib
, rustPlatform
, fetchFromGitHub
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "drips";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "drips";
    tag = "v${finalAttrs.version}";
    hash = "sha256-jsvGzy4b4FEEiv7udBGVUdjHuikxrs2K9WM6JOuBjiI=";
  };

  cargoHash = "sha256-ZX2PymhPKrQDdH0MeRbbSBNNtlCSM6uTehUtcAIST3E=";

  meta = {
    description = "A quick cli tool to apply ips/ups patches to files";
    homepage = "https://github.com/jpetrucciani/drips";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "drips";
  };
})
