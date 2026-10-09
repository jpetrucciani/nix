# mcp

This directory contains Model Context Protocol (MCP) servers

---

## In this directory

### [chrome-devtools-mcp-headless.nix](./chrome-devtools-mcp-headless.nix)

[`chrome-devtools-mcp`](https://www.npmjs.com/package/chrome-devtools-mcp) runs the Chrome DevTools MCP server with the bundled Chromium in headless mode.

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
