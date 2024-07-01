{ lib
, system
, stdenv
, darwin
, nightlyRustPlatform
, fetchFromGitHub
, openssl
, pkg-config
, python3
}:
let
  inherit (stdenv) isAarch64 isDarwin;
  isM1 = isDarwin && isAarch64;
  osSpecific =
    if isM1 then with darwin.apple_sdk_11_0.frameworks; [ Accelerate MetalKit MetalPerformanceShaders MetalPerformanceShadersGraph ]
    else if isDarwin then with darwin.apple_sdk.frameworks; [ Accelerate CoreGraphics CoreVideo ]
    else [ ];
  swaggerUIZip = builtins.fetchurl {
    url = "https://github.com/swagger-api/swagger-ui/archive/refs/tags/v5.17.12.zip";
    sha256 = "1wh7yrkyc87zkzdyxbhpzcvykmmz2zkbsj9h0ny2mmryjby37bhw";
  };
in
nightlyRustPlatform.buildRustPackage rec {
  pname = "mistral-rs";
  version = "0.1.24";

  src = fetchFromGitHub {
    owner = "EricLBuehler";
    repo = "mistral.rs";
    rev = "v${version}";
    hash = "sha256-oBVgA46GuXPgs+Y6AmqDNRfvPD+n2FO1czp2Gbl3BNg=";
  };

  SWAGGER_UI_DOWNLOAD_URL = "file://${swaggerUIZip}";

  buildInputs = [
    openssl
  ] ++ osSpecific;
  nativeBuildInputs = [ pkg-config python3 ];

  cargoLock = {
    lockFile = builtins.fetchurl {
      url = "https://cobi.dev/static/cargolock/${pname}/${version}.lock";
      sha256 = "0kvk7j22vij69w5xd1ypkdflvsgp9rawkmyyfcmlnn9235fm24b1";
    };
    outputHashes = {
      "candle-core-0.6.0" = "sha256-vDKBTfVWAaSU/JxHe9UvskOpd/ngMV3sKFLcYcOMBJs=";
      "range-checked-0.1.0" = "sha256-S+zcF13TjwQPFWZLIbUDkvEeaYdaxCOtDLtI+JRvum8=";
    };
  };

  meta = with lib; {
    description = "Blazingly fast LLM inference";
    homepage = "https://github.com/EricLBuehler/mistral.rs";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "mistral-rs";
  };
}
