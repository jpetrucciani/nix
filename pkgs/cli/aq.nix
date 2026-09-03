{ lib
, rustPlatform
, fetchFromGitHub
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "aq";
  version = "0.1.4";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "aq";
    tag = "v${finalAttrs.version}";
    hash = "sha256-dpfl0apRAFraYGf8YNjyooPfL9h1C0q2ykvrx8lWxj0=";
  };

  cargoHash = "sha256-/A4KQq0SPieGsJggMACJ9GhSLefKF7GGz9OsHrRb1Ag=";

  meta = {
    description = "Multi-format data processing tool";
    homepage = "https://github.com/jpetrucciani/aq";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "aq";
  };
})
