{ lib
, writeShellApplication
, stdenvNoCC
, fetchurl
, nix-update-script
, bun
, chromium
, google-chrome
}:
let
  browser = if stdenvNoCC.hostPlatform.isDarwin then google-chrome else chromium;

  # Upstream's npm release bundles its runtime JavaScript dependencies.
  server = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "chrome-devtools-mcp";
    version = "1.11.0";

    src = fetchurl {
      url = "https://registry.npmjs.org/chrome-devtools-mcp/-/chrome-devtools-mcp-${finalAttrs.version}.tgz";
      hash = "sha512-CytJ/5tnzrS+J/74be2P5aCOsS/mmGRHys/Si+IYC4ucrbnWAmES/dYdxGJjeUCECRcoFUilZAysdjlwqUjXIA==";
    };

    dontBuild = true;
    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -r . "$out/"

      runHook postInstall
    '';
  });
in
writeShellApplication {
  name = "chrome-devtools-mcp-headless";
  text = ''
    set -euo pipefail

    export CHROME_BIN="${lib.getExe browser}"
    export CHROME_PATH="$CHROME_BIN"
    export PUPPETEER_EXECUTABLE_PATH="$CHROME_BIN"
    export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}"
    export CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS=1

    exec ${lib.getExe bun} ${server}/build/src/bin/chrome-devtools-mcp.js \
      --headless \
      --isolated \
      --no-usage-statistics --no-performance-crux \
      --executable-path "$CHROME_BIN" \
      --chrome-arg="--no-first-run" \
      --chrome-arg="--no-default-browser-check" \
      --chrome-arg="--disable-background-networking" \
      ${lib.optionalString stdenvNoCC.hostPlatform.isLinux "--chrome-arg=--no-sandbox"} \
      "$@"
  '';
  derivationArgs.version = server.version;
  passthru = {
    inherit (server) src;
    updateScript = nix-update-script { };
  };
  meta = {
    description = "Chrome DevTools MCP server with a headless browser and bundled runtime dependencies";
    homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "chrome-devtools-mcp-headless";
    platforms = lib.platforms.linux ++ [ "aarch64-darwin" ];
  };
}
