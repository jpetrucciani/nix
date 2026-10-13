{ lib
, rustPlatform
, fetchFromGitHub
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "aq";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "aq";
    tag = "v${finalAttrs.version}";
    hash = "sha256-eRrF2kvZUMPtMfXgNThFER7gGLNEylB8p/mB0d3fWhs=";
  };

  cargoHash = "sha256-YCXxvIUQ5ehZGtmFX4npW8iLtHHiQ4okiD5WLObRuig=";

  meta = {
    description = "Multi-format data processing tool";
    homepage = "https://github.com/jpetrucciani/aq";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "aq";
  };
})
