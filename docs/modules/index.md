# Modules

Reusable system modules live under `hosts/modules`. A module is a reusable configuration fragment. It usually defines options, service wiring, and defaults that several machines can share.

This is where behavior that should apply to more than one machine belongs.

## Module Areas

- `hosts/modules/conf`
  General configuration helpers used by hosts.
- `hosts/modules/darwin`
  nix-darwin launchd and service modules.
- `hosts/modules/exporters`
  Monitoring-specific modules like `nvme`.
- `hosts/modules/games`
  Game server modules.
- `hosts/modules/servers`
  Reusable NixOS services and self-hosted applications.

## What To Look For

- A host should import a module because the behavior is reusable, not because the host file is getting crowded.
- Modules are where service defaults, option wiring, and systemd or launchd integration should live.
- The interesting read is usually one module plus one host that imports it.

## Module Vs Package

- A package builds software.
- A module configures software or a subsystem.
- Many useful repo features involve both, a package to produce the binary, then a module to run and configure it.

## Suggested Examples

- `hosts/modules/servers/minifluxng.nix`
- `hosts/modules/servers/obligator.nix`
- `hosts/modules/darwin/ollama.nix`
- `hosts/modules/exporters/nvme.nix`

For one full package -> module -> host walkthrough, see [Case Study: `poglets`](/case-study-poglets).

## Complete Inventory

For the full generated list, see [Generated Module Index](/reference/generated-modules).
