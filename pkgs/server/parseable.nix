# [parseable](https://github.com/parseablehq/parseable) is a log analytics system written in Rust
{ lib
, rustPlatform
, stdenvNoCC
, fetchFromGitHub
, pkg-config
, bzip2
, openssl
, xz
, zstd
, stdenv
, unzip
, darwin
}:
let
  frontend =
    let
      pname = "parseable-frontend";
      version = "0.2.4";
    in
    stdenvNoCC.mkDerivation rec {
      inherit pname version;
      src = builtins.fetchurl {
        url = "https://github.com/parseablehq/console/releases/download/v${version}/build.zip";
        sha256 = "1i4nhz2knzm0x1crmixpcigs2gzcc48x3b1zzssmsqn7lab9vjcq";
      };
      dontConfigure = true;
      dontBuild = true;
      unpackPhase = ''
        ${unzip}/bin/unzip ${src}
      '';
      installPhase = ''
        mkdir -p $out
        cp -r . $out
      '';
    };
in
rustPlatform.buildRustPackage rec {
  pname = "parseable";
  version = "0.6.2";

  src = fetchFromGitHub {
    owner = "parseablehq";
    repo = "parseable";
    rev = "v${version}";
    hash = "sha256-Gjx/2LNoeTcLNf0kXmEdQ6O8WB53jic8KhV72h9Fd6A=";
  };

  cargoHash = "sha256-86j2LzRnmY6KRsfnF4trZoSmnibwbGxFA9U2b++mml4=";

  LOCAL_ASSETS_PATH = "${frontend}/dist";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    bzip2
    openssl
    xz
    zstd
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.Security
  ];

  env = {
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  meta = with lib; {
    description = "Log analytics system written in Rust. It is built for high throughput log ingestion cases";
    homepage = "https://github.com/parseablehq/parseable";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
