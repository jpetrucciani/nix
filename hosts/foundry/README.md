# foundry

This directory defines the base NixOS configuration used when this repo builds cloud VM images and installer ISOs through [nixos-generators](https://github.com/nix-community/nixos-generators).

It is not a normal day-to-day machine profile. Think of it as the common image template behind the `osGenerators.<format>` outputs from `flake.nix`.

## What It Is Used For

- building install and rescue ISOs
- building cloud images for providers like AWS, Azure, GCE, and DigitalOcean
- building VM images for formats like VirtualBox, VMware, Hyper-V, and Proxmox
- bootstrapping a minimal but useful admin environment with SSH, Tailscale, and common debugging tools

## Related Surfaces

- `flake.nix` exposes the `osGenerators.<format>` outputs that use this profile
- `.github/workflows/foundry.yml` handles the related container-image publishing workflow
- `mods/foundry.nix` builds the task-focused container images that share the same foundry name, but that is a separate surface from this host profile

---

## In this directory

### [configuration.nix](./configuration.nix)

This contains the base NixOS configuration shared by the generated cloud and installer images.
