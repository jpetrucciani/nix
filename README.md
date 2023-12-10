# nix

[![uses nix](https://img.shields.io/badge/uses-nix-%237EBAE4)](https://nixos.org/)

_nixpkgs configurations, overlays, and info_

## In this repo

### interesting stuff

#### [hex](./mods/pog/hex/)

Hex is a nix module system that allows us to create powerful abstractions of other languages and configurations via nix! At the moment, this is the most useful for things like kubernetes specs!

#### [pog](./mods/pog.nix)

This set of nix functions has proven to be extremely useful to me - it is a quick CLI tool generator that leverages the power of nix!

[See many examples of how it can be used here!](./mods/pog/) Some fun files/examples to look at:

- [ffmpeg - tired of trying to remember that arcane ffmpeg invocation? wrap it in pog!](./mods/pog/ffmpeg.nix)
- [ktools - kubectl wrapper cli tools that make it easier to interact with clusters and their resources](./mods/pog/k8s.nix)
- [dtools - docker wrapper cli tools that make it easier to interact with docker](./mods/pog/docker.nix)

#### [python packages](./mods/python/)

I maintain a large number of nix python packages that are available as overlays from this repo!

### directories

#### [.github/](./.github/)

This directory contains my GitHub actions, which automatically check for updates to various sources, and rebuild and cache my nix setups for various platforms.

#### [examples/](./examples/)

This directory contains examples of use of my repo as a source for other tools/environments!

#### [hosts/](./hosts/)

This directory contains my NixOS configurations for each of my NixOS machines, as well as a `common.nix` file that contains shared configurations for my servers/clients.

#### [mods/](./mods/)

This directory contains my overlays for nixpkgs, but configured in a way that others can reuse specific parts of my overlays if they'd like to use this repo as a source.

#### [pkgs/](./pkgs/)

This directory contains nix packages that I've built that might not be yet ready for nixpkgs proper, or that don't make sense to open as a PR to nixpkgs proper.

#### [scripts/](./scripts/)

This directory contains various random scripts that I use in this repo, or in packages created by this repo.

#### [secrets/](./secrets/)

This directory contains encrypted secrets for my nixos machines, using [agenix](https://github.com/ryantm/agenix).

#### [default.nix](./default.nix)

This file acts as the entrypoint for nix to pin my nixpkgs version to the rev and sha256 found [in the flake.lock](./flake.lock).

#### [flake.nix](./flake.nix)

My main flake file

#### [home.nix](./home.nix)

This file contains my main [home-manager](https://github.com/nix-community/home-manager) configuration. This includes all sorts of packages, configurations, and dotfiles for pretty much all software that I use.

#### [overlays.nix](./overlays.nix)

This file declares the overlays that I apply to my pinned version of nixpkgs. This should load the files in the [mods](./mods/) directory, which are overlay functions which apply to my nixpkgs object in nix. **note that this file is much more verbose than required! personally, I prefer the explicitness here**
