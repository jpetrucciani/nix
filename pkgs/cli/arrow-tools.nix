{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, cmake
, zstd
}:
rustPlatform.buildRustPackage rec {
  pname = "arrow-tools";
  version = "0.22.3";

  src = fetchFromGitHub {
    owner = "domoritz";
    repo = "arrow-tools";
    rev = "v${version}";
    hash = "sha256-RtckvxFP4mZ/0OowrAok5QICIsrzhozaVcfrf/ejaLE=";
  };

  cargoHash = "sha256-WWZmAhb98jhtSDeihUbTTMNgziglQQnDaBP5c+xv2BI=";

  nativeBuildInputs = [
    pkg-config
    cmake
  ];

  buildInputs = [
    zstd
  ];

  env = {
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  meta = {
    description = "A collection of handy CLI tools to convert CSV and JSON to Apache Arrow and Parquet";
    homepage = "https://github.com/domoritz/arrow-tools";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "arrow-tools";
  };
}
