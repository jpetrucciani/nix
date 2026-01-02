{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, cmake
, zstd
}:
rustPlatform.buildRustPackage rec {
  pname = "arrow-tools";
  version = "0.24.4";

  src = fetchFromGitHub {
    owner = "domoritz";
    repo = "arrow-tools";
    rev = "v${version}";
    hash = "sha256-TZWR7oRPdxZyz2rZ/qI/ou4niqQBSU1RAIpoYbtLhiw=";
  };

  cargoHash = "sha256-95HiCkXkiPDpo7MyW4k+fQPzhARO6KvF8fPnuyFEfTI=";

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
