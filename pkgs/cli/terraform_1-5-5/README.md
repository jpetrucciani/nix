# terraform_1-5-5

This directory contains a pinned Terraform `1.5.5` build for legacy workflows that still need that exact track.

The package uses the shared `mkTerraform` helper and applies a local provider path patch so older flows continue to behave the way this repo expects.

---

## In this directory

### [default.nix](./default.nix)

This file defines the pinned Terraform derivation, including the version, source hash, vendored dependency hash, and the local patch list.

### [provider-path-0_15.patch](./provider-path-0_15.patch)

This patch preserves the provider path behavior needed by the legacy Terraform 1.5.5 packaging flow.
