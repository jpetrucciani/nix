{ fetchFromGitHub
, fetchNpmDeps
, lib
, nix-update-script
, nodejs
, npmHooks
, pkg-config
, rustPlatform
, sqlite
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "picomq";
  version = "0.1.0-unstable-2026-08-23";

  src = fetchFromGitHub {
    owner = "picomq";
    repo = "picomq";
    rev = "b5302bebb6b77f5631def2861d4178847704aa6a";
    hash = "sha256-1e5/ziT4Pucs5ZJPzDrEVd22FVQP3+YOWqyaUm8Xgow=";
  };

  cargoHash = "sha256-XPQV1hOWLFSOqzy2IoHO0WzQVXhvtzG5dU3/5a6x2H4=";

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
    sqlite
  ];

  preBuild = ''
    pushd ${finalAttrs.npmRoot}
    npm run build
    popd

    test -s picomq/pico-frontend/_dashboard/index.html
  '';

  cargoBuildFlags = [
    "--package"
    "pico-cli"
  ];

  cargoTestFlags = [
    "--package"
    "pico-cli"
  ];

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    $out/bin/pico --help >/dev/null
    $out/bin/pico --version | grep -F "pico 0.1.0"

    runHook postInstallCheck
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch=main" ];
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
