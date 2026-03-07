# Packages

Package definitions live under [`pkgs/*`](https://github.com/jpetrucciani/nix/tree/main/pkgs). A package is the answer to "how do I build or install this software?" The important part in this repo is how those package files are exposed. [`mods/_pkgs.nix`](https://github.com/jpetrucciani/nix/blob/main/mods/_pkgs.nix) recursively imports them into the overlayed package set, and [`mods/pkgs/*.nix`](https://github.com/jpetrucciani/nix/tree/main/mods/pkgs) builds higher-level package families on top.

## What This Layer Does

- Keeps custom derivations in-repo instead of scattering one-off package files across host configs.
- Exposes those derivations as top-level attrs in the shared package set.
- Lets hosts, Home Manager, and helper tools all consume the same package outputs.

## Package Vs Module

- A package builds software.
- A module configures or runs software.
- A host decides which packages and modules a machine gets.

## Package Areas

- `pkgs/ai`
- `pkgs/cli`
- `pkgs/cloud`
- `pkgs/k8s`
- `pkgs/lib`
- `pkgs/mcp`
- `pkgs/misc`
- `pkgs/prometheus`
- `pkgs/server`
- `pkgs/uv`

## Selected Examples

- [`pkgs/cli/mica.nix`](https://github.com/jpetrucciani/nix/blob/main/pkgs/cli/mica.nix), which packages [`mica`](/tooling/mica), a terminal UI for managing Nix environments.
- [`pkgs/cloud/gcsproxy.nix`](https://github.com/jpetrucciani/nix/blob/main/pkgs/cloud/gcsproxy.nix), a reusable proxy around Google Cloud Storage.
- [`pkgs/server/obligator.nix`](https://github.com/jpetrucciani/nix/blob/main/pkgs/server/obligator.nix), a self-hosted OpenID Connect server.
- [`pkgs/server/poglets.nix`](https://github.com/jpetrucciani/nix/blob/main/pkgs/server/poglets.nix), a TCP tunneling service.
- [`pkgs/mcp/loki-mcp.nix`](https://github.com/jpetrucciani/nix/blob/main/pkgs/mcp/loki-mcp.nix), [`pkgs/mcp/ntfy-mcp.nix`](https://github.com/jpetrucciani/nix/blob/main/pkgs/mcp/ntfy-mcp.nix), and [`pkgs/mcp/prom-mcp.nix`](https://github.com/jpetrucciani/nix/blob/main/pkgs/mcp/prom-mcp.nix), MCP servers for operational systems.
- [`pkgs/uv/vllm.nix`](https://github.com/jpetrucciani/nix/blob/main/pkgs/uv/vllm.nix), a packaged high-throughput inference runtime.

## How To Read This Layer

1. Read one package under `pkgs/*`.
2. Read [`mods/_pkgs.nix`](https://github.com/jpetrucciani/nix/blob/main/mods/_pkgs.nix) to see how package files become attrs.
3. Read [`mods/pkgs/*.nix`](https://github.com/jpetrucciani/nix/tree/main/mods/pkgs) if you want the higher-level curated package sets.

For one concrete package -> module -> host walkthrough, see [Case Study: `poglets`](/case-study-poglets).

## Complete Inventory

For the full generated list, see [Generated Package Index](/reference/generated-packages).
