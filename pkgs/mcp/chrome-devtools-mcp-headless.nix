{ lib
, writeShellApplication
, bun
, chromium
, coreutils
, bash
}:
writeShellApplication {
  name = "chrome-devtools-mcp-headless";

  runtimeInputs = [
    bun
    chromium
    coreutils
    bash
  ];
  text = ''
    set -euo pipefail

    export CHROME_BIN="${chromium}/bin/chromium"
    export CHROME_PATH="$CHROME_BIN"
    export PUPPETEER_EXECUTABLE_PATH="$CHROME_BIN"
    export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}"

    exec ${bun}/bin/bunx --bun chrome-devtools-mcp@latest \
      --headless \
      --isolated \
      --executable-path "$CHROME_BIN" \
      --chrome-arg="--no-first-run" \
      --chrome-arg="--no-default-browser-check" \
      --chrome-arg="--disable-background-networking" \
      --chrome-arg="--no-sandbox" \
      "$@"
  '';
  meta = {
    platforms = lib.platforms.linux;
  };
}
