# cy1-nix-01

This is a NixOS work machine on the BlackEdge network. It inherits the shared `hosts/common.nix` base, enables the `conf.blackedge` module, and carries a few network and storage choices that are specific to that environment.

## What Is Special Here

- uses internal `blackedge.local` DNS and search domains
- mounts shared SMB and NFS resources
- exposes a local SOCKS proxy via `services._3proxy`
- keeps the firewall disabled because it lives on a trusted internal network

---

## In this directory

### [configuration.nix](./configuration.nix)

This file defines the machine configuration, imports the shared host base, and enables the BlackEdge-specific module and network/storage settings.

### [hardware-configuration.nix](./hardware-configuration.nix)

This file contains the generated hardware profile for the machine.
