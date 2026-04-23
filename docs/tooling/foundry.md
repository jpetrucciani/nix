# foundry

`foundry` is the repo's shared image-building surface.

It covers two related jobs:

- building cloud and installer operating system images from [`hosts/foundry/configuration.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/foundry/configuration.nix) through the `osImages.<variant>` flake outputs
- building task-focused container images from [`mods/foundry.nix`](https://github.com/jpetrucciani/nix/blob/main/mods/foundry.nix) through the `foundry.<name>` package family

The name is shared because both surfaces are about "forge a practical image from the repo's package universe", but they solve different deployment problems.

## What It Is Good For

- creating bootable installer or rescue media
- creating cloud images for provider-specific imports
- publishing focused container images with exactly the tools or runtime a job needs
- reusing the same pinned package set and overlays for both VM-style and container-style artifacts

## The Two Foundry Surfaces

### OS images

[`flake.nix`](https://github.com/jpetrucciani/nix/blob/main/flake.nix) exposes `osImages.<variant>` outputs such as:

- `.#osImages.iso`
- `.#osImages.iso-installer`
- `.#osImages.amazon`
- `.#osImages.google-compute`
- `.#osImages.google-compute-cuda`
- `.#osImages.proxmox`

All of those use [`hosts/foundry/configuration.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/foundry/configuration.nix) as the shared base profile, with [`hosts/foundry/images.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/foundry/images.nix) extending nixpkgs' native `system.build.images` variant set. That profile keeps things intentionally practical: SSH access, Tailscale, common shell/debug tools, and enough network driver coverage to boot on varied targets.

Typical use case: build a machine image that you will import into a cloud or boot directly as installation media.

### Container images

[`mods/foundry.nix`](https://github.com/jpetrucciani/nix/blob/main/mods/foundry.nix) builds a family of container images such as:

- `foundry.nix`
- `foundry.python312`
- `foundry.python313`
- `foundry.k8s_aws`
- `foundry.certbot`
- `foundry.hex`
- `foundry.zaddy`

These images are built with `nix2container`, carry a curated tool/runtime set, and in most cases include a working Nix install inside the image.

Typical use case: publish a reusable operations or build image to a registry without hand-maintaining a Dockerfile stack.

## How CI Uses It

[`foundry.yml`](https://github.com/jpetrucciani/nix/blob/main/.github/workflows/foundry.yml) publishes the container-image side of `foundry` to `ghcr.io`. That workflow logs into the registry, copies the built image, and also tags it with `latest` plus a date-based tag.

The OS-image side is not a registry publishing flow. It is a build surface for artifacts like ISOs and cloud images.

## Typical Commands

Build an operating system image:

```bash
nix build .#osImages.iso
nix build .#osImages.amazon
```

Build one of the container images:

```bash
nix build .#foundry.nix
nix build .#foundry.python312
```

If you are inspecting the registry-publish workflow itself, the CI job uses `copyToRegistry` on the foundry package outputs:

```bash
nix run --impure .#foundry.python312.copyToRegistry
```

## Why It Belongs In This Repo

- It reuses the same pinned `pkgs` and overlays as the rest of the tree.
- It gives the repo a practical artifact story beyond "build a host" or "build a package".
- It keeps OS images and container images close to the packages and modules they depend on.

## What To Read

- [`hosts/foundry/configuration.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/foundry/configuration.nix)
- [`mods/foundry.nix`](https://github.com/jpetrucciani/nix/blob/main/mods/foundry.nix)
- [`flake.nix`](https://github.com/jpetrucciani/nix/blob/main/flake.nix)
- [CI and Automation](/ci-and-automation)

## Read Next

- [Architecture](/architecture)
- [Tooling Overview](/tooling/index)
- [Daily Workflows](/daily-workflows)
