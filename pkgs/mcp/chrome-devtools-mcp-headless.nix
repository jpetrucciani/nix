{ lib
, writeShellApplication
, stdenvNoCC
, fetchurl
, nix-update-script
, bun
, chromium
, dejavu_fonts
, liberation_ttf
, makeFontsConf
, noto-fonts-color-emoji
, google-chrome
}:
let
  browser = if stdenvNoCC.hostPlatform.isDarwin then google-chrome else chromium;
  # MCP clients (codex) often start servers with a scrubbed env, and Chromium with no fonts
  # renders blank text, then aborts in font fallback on most real pages.
  fontsConf = makeFontsConf {
    fontDirectories = [ dejavu_fonts liberation_ttf noto-fonts-color-emoji ];
  };

  # Upstream's npm release bundles its runtime JavaScript dependencies.
  server = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "chrome-devtools-mcp";
    version = "1.12.0";

    src = fetchurl {
      url = "https://registry.npmjs.org/chrome-devtools-mcp/-/chrome-devtools-mcp-${finalAttrs.version}.tgz";
      hash = "sha256-Sq3jFnw+eBx5fWEJ7WA6DKW4yzY6KJ4uqsqpsMXSo2A=";
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
    ${lib.optionalString stdenvNoCC.hostPlatform.isLinux ''export FONTCONFIG_FILE="''${FONTCONFIG_FILE:-${fontsConf}}"''}

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
    inherit browser;
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
