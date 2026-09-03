{ fetchFromGitHub
, fetchNpmDeps
, lib
, nix-update-script
, nodejs
, npmHooks
, pkg-config
, rdkafka
, rustPlatform
, sqlite
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "picomq";
  version = "unstable-2026-09-02";

  src = fetchFromGitHub {
    owner = "picomq";
    repo = "picomq";
    rev = "f425605b920717b31dd10b6acea0e4411f0cea42";
    hash = "sha256-KZ0SOuqVhLiW/fWWLaN5SHYv5aQr6HbjI9gOzwmKEuU=";
  };

  cargoHash = "sha256-PwT87wEN5GtTzrp18f4DIPcv1403n55hb/TxL9zIdgE=";

  npmRoot = "dashboard";
  npmDeps = fetchNpmDeps {
    name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps";
    inherit (finalAttrs) src;
    preBuild = ''
      pushd ${finalAttrs.npmRoot}
    '';
    hash = "sha256-3sA/07pFoGoO1SI7OdrutNfFBh9s57e6QwyhK4zw24o=";
  };

  nativeBuildInputs = [
    nodejs
    npmHooks.npmConfigHook
    pkg-config
  ];

  buildInputs = [
    rdkafka
    sqlite
  ];

  CARGO_FEATURE_DYNAMIC_LINKING = 1;

  preBuild = ''
    pushd ${finalAttrs.npmRoot}
    npm run build
    popd

    test -s picomq/pico-http/_dashboard/index.html
  '';

  cargoBuildFlags = [
    "--package"
    "picomq-cli"
  ];

  cargoTestFlags = [
    "--package"
    "picomq-cli"
  ];
  # The CLI tests reserve ports before spawning their servers, so parallel
  # cases can select each other's ports and fail with EADDRINUSE.
  dontUseCargoParallelTests = true;

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    $out/bin/pico --help >/dev/null
    $out/bin/pico --version | grep -F "pico 0.1.0"

    runHook postInstallCheck
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch=main"
      "--version-regex=.*(unstable-[0-9-]+)$"
    ];
  };

  meta = {
    description = "Durable real-time streams over HTTP backed by S3-compatible object storage";
    homepage = "https://github.com/picomq/picomq";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "pico";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
