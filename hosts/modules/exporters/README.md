# exporters

This directory contains monitoring-oriented NixOS modules for exporter services.

These modules are for the "small reusable daemon" case: define an option surface, wire the service unit, and let hosts or `snowball` bundles turn them on when needed.

---

## In this directory

### [nvme.nix](./nvme.nix)

This module exposes `services.nvme-exporter.*` options for running `nvme-exporter` as a managed NixOS service, including listen address, port, firewall, and runtime user controls.
