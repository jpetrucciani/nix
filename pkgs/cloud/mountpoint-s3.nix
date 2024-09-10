{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, libgit2
, zlib
, stdenv
, cmake
, darwin
, fuse3
}:

rustPlatform.buildRustPackage rec {
  pname = "mountpoint-s3";
  version = "1.8.0";

  src = fetchFromGitHub {
    owner = "awslabs";
    repo = "mountpoint-s3";
    rev = "mountpoint-s3-${version}";
    hash = "sha256-0SygSRp2HXgLhW0BscRhH3H/WUstAf6VbQPJ35ffrRM=";
    fetchSubmodules = true;
  };

  cargoHash = "sha256-nkTvVfbpi5yvWpRd1Tm6INi3PrR6mP8VkBpIVeCEkw0=";

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
    cmake
  ];

  buildInputs = [
    fuse3
    libgit2
    zlib
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.Security
  ];

  meta = {
    description = "A simple, high-throughput file client for mounting an Amazon S3 bucket as a local file system";
    homepage = "https://github.com/awslabs/mountpoint-s3";
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "mountpoint-s3";
  };
}
