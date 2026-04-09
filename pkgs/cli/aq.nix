{ lib
, rustPlatform
, fetchFromGitHub
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "aq";
  version = "0.1.3";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "aq";
    tag = "v${finalAttrs.version}";
    hash = "sha256-KYuJ0RHT21KWtqeQrozcTrFVqCf+aENxuNiLEYykcMY=";
  };

  cargoHash = "sha256-oPY5nw5eKCyI2Ynhmr3eaZgI2ALwsn+QCjPWOjH4wcs=";

  meta = {
    description = "Multi-format data processing tool";
    homepage = "https://github.com/jpetrucciani/aq";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "aq";
  };
})
