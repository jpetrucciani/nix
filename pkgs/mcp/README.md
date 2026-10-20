# mcp

This directory contains Model Context Protocol (MCP) servers

---

## In this directory

### [chrome-devtools-mcp-headless.nix](./chrome-devtools-mcp-headless.nix)

[`chrome-devtools-mcp`](https://www.npmjs.com/package/chrome-devtools-mcp) runs the Chrome DevTools MCP server with a bundled browser in headless mode.
Linux uses Chromium; Apple Silicon macOS (`aarch64-darwin`) uses nixpkgs' Google Chrome package, which has an unfree license.
Nix pins upstream's bundled JavaScript release by version and hash, with Bun and the browser in the runtime closure.
Startup needs no `bunx`, npm registry access, or browser downloads; update checks, usage statistics, and CrUX requests are disabled.
For airgapped use, transfer the complete runtime closure to the target machine with `nix copy` or `nix-store --export` / `--import`.
Browser profiles and caches still need writable runtime storage.
Update the MCP bundle with `nix run .#nupdate -- chrome-devtools-mcp-headless`; the scheduled package updater also includes it.
The browser and Bun follow the repository's nixpkgs pin and update with the flake lock.

### [ferry.nix](./ferry.nix)

[`ferry`](https://github.com/jpetrucciani/ferry) is a stdio/sse/streamable http transport to ferry your mcp access across the network/proxies

### [loki-mcp.nix](./loki-mcp.nix)

[`loki-mcp`](https://github.com/jpetrucciani/loki-mcp) is an MCP server for querying Loki logs.

### [netbox-mcp-server.nix](./netbox-mcp-server.nix)

[`netbox-mcp-server`](https://github.com/netboxlabs/netbox-mcp-server) provides read-only NetBox access over MCP.
It packages upstream's locked runtime dependencies with Nix Python 3.14, so startup needs no `uvx` or Python downloads.
Set `NETBOX_URL` and `NETBOX_TOKEN` at runtime; stdio is the default transport.
Run `netbox-mcp-server --help` to see the available options without supplying credentials.

### [prom-mcp.nix](./prom-mcp.nix)

[`prom-mcp`](https://github.com/jpetrucciani/prom-mcp) is an MCP server for querying Prometheus metrics.

### [roslyn-mcp/](./roslyn-mcp/)

[`roslyn-mcp`](https://github.com/jpetrucciani/RoslynMCP) is an MCP server for C# code analysis and navigation using Roslyn.

### [ntfy-mcp.nix](./ntfy-mcp.nix)

[`ntfy-mcp`](https://github.com/jpetrucciani/ntfy-mcp) is a lightweight MCP server for ntfy notifications.
