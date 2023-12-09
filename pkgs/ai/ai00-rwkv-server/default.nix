{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, bzip2
, vulkan-loader
, zstd
, stdenv
, darwin
}:

rustPlatform.buildRustPackage rec {
  pname = "ai00-rwkv-server";
  version = "0.3.4";

  src = fetchFromGitHub {
    owner = "cgisky1980";
    repo = "ai00_rwkv_server";
    rev = "v${version}";
    hash = "sha256-bGvr6bpdDpPncaXYD9Yn14ArTk3ziwlLAM+hfe4nhuM=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "web-rwkv-0.4.4" = "sha256-sm+lozaS0tYnDVOVuN/ucXUhrkuAaP5Rb6yBKSq9vas=";
    };
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    bzip2
    vulkan-loader
    zstd
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.CoreGraphics
    darwin.apple_sdk.frameworks.Metal
    darwin.apple_sdk.frameworks.QuartzCore
  ];

  env = {
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  meta = with lib; {
    description = "A localized open-source AI server that is better than ChatGPT";
    homepage = "https://github.com/cgisky1980/ai00_rwkv_server";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "ai00-rwkv-server";
  };
}
