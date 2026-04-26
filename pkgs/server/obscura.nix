{ lib
, rustPlatform
, fetchFromGitHub
, fetchLibrustyV8
, pkg-config
, openssl
, zstd
}:

let
  librustyV8 = fetchLibrustyV8 {
    version = "137.3.0";
    hashes = {
      aarch64-darwin = "sha256-YFA9ZyTlUsRrAewmChXnnobEcVtxl8XGJ0iRG/H04HA=";
      aarch64-linux = "sha256-42jQy0HBecQ6mQ5OxKVeRN2XYvHTS+FWlqzEQz+KbJI=";
      x86_64-linux = "sha256-omgf3lMBir0zZgGPEyYX3VmAAt948VbHvG0v9gi1ZWc=";
    };
  };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "obscura";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "h4ckf0r0day";
    repo = "obscura";
    tag = "v${finalAttrs.version}";
    hash = "sha256-SCK9pDTODUNaTUb2yxe+cGNvQTMErWkFj5ZLu0dXYq8=";
  };

  cargoHash = "sha256-+q7KeXr69wv3SoJ5qTQOxomCGpA+JdoZ04Hv9jExiZU=";

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    openssl
    zstd
  ];

  env = {
    OPENSSL_NO_VENDOR = true;
    RUSTY_V8_ARCHIVE = librustyV8;
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  meta = {
    description = "The headless browser for AI agents and web scraping";
    homepage = "https://github.com/h4ckf0r0day/obscura";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "obscura";
  };
})
