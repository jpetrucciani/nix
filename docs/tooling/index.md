# Tooling

The most distinctive parts of this repo are not just the packages or host files. They are the tools built around them.

You do not need to understand every tool here on a first read. For newcomers, this section is most useful after [Architecture](/architecture) and [Home Manager](/home-manager), when the shared package-set model is already clear.

## Key Surfaces

- [`pog`](/tooling/pog), the CLI wrapper system used throughout [`mods/pog/*`](https://github.com/jpetrucciani/nix/tree/main/mods/pog).
- [`hex`](/tooling/hex), the Nix-driven spec and render workflow used here for Kubernetes-oriented configuration.
- [`snowball`](/tooling/snowball), a targeted way to package up and deploy portable systemd service bundles via [`mods/snowball.nix`](https://github.com/jpetrucciani/nix/blob/main/mods/snowball.nix).
- [`foundry`](/tooling/foundry), the repo's shared image-building surface for cloud/installer OS images and task-focused container images.
- [`mica`](/tooling/mica), a lighter package-focused environment manager that complements Home Manager.
- [`hms` and `hmx`](/tooling/hms-and-hmx), the repo's preferred rebuild and switch helpers defined in [`mods/hms.nix`](https://github.com/jpetrucciani/nix/blob/main/mods/hms.nix).
- [`scripts.nix` outputs](/tooling/scripts), checked shell-script utilities exposed as flake outputs from [`scripts.nix`](https://github.com/jpetrucciani/nix/blob/main/scripts.nix).

## Why This Matters

This repo is opinionated about ergonomics. The point is not only to define packages and systems, but to turn them into a workflow that is actually pleasant to use.

## Outside Links

- `pog` docs: <https://pog.gemologic.dev/>
- `pog` repo: <https://github.com/jpetrucciani/pog>
- `hex` docs: <https://hex.gemologic.dev/>
- `hex` repo: <https://github.com/jpetrucciani/hex>
- `mica` repo: <https://github.com/gemologic/mica>
