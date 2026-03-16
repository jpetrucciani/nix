# Hosts

This repo manages both NixOS and nix-darwin machines from one codebase. A host is a concrete machine definition. If a package builds software and a module defines reusable behavior, a host chooses the exact combination for one machine.

Hosts are intentionally thin. Shared behavior belongs in modules and overlays, while `hosts/<name>/configuration.nix` contains the machine-specific decisions.

## Key Files

- [`hosts/constants.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/constants.nix): host names, machine groups, ports, key material, shared constants.
- [`hosts/common.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/common.nix): shared NixOS defaults.
- [`hosts/common_darwin.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/common_darwin.nix): shared darwin defaults.
- [`hosts/<name>/configuration.nix`](https://github.com/jpetrucciani/nix/tree/main/hosts): per-host config.

## Host Families

- **NixOS hosts** have a `hardware-configuration.nix` and build through `.#nixosConfigurations.<host>.config.system.build.toplevel`.
- **nix-darwin hosts** build through `.#darwinConfigurations.<host>.system`.

## Representative Examples

- [`hosts/cy1-nix-01/configuration.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/cy1-nix-01/configuration.nix), a work-network NixOS machine with BlackEdge-specific networking and shared storage mounts.
- [`hosts/voyager/configuration.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/voyager/configuration.nix), a WSL-focused NixOS setup.
- [`hosts/pluto/configuration.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/pluto/configuration.nix), a nix-darwin laptop setup.

## Host Vs Module

- A host is specific, one machine, one set of choices.
- A module is reusable, something several hosts can import.

## How To Read This Layer

1. Start with `hosts/constants.nix`.
2. Read [`hosts/common.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/common.nix) or [`hosts/common_darwin.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/common_darwin.nix).
3. Open one concrete host directory under [`hosts/`](https://github.com/jpetrucciani/nix/tree/main/hosts).
4. Follow any imported modules into [`hosts/modules/*`](https://github.com/jpetrucciani/nix/tree/main/hosts/modules).

For one concrete package -> module -> host walkthrough, see [Case Study: `poglets`](/case-study-poglets).

## How To Test Changes

```bash
# nixos
nix build .#nixosConfigurations.<host>.config.system.build.toplevel

# darwin
nix build .#darwinConfigurations.<host>.system
```

## Complete Inventory

For the full generated host list, see [Generated Host Index](/reference/generated-hosts).
