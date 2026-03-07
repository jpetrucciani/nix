# Architecture

This repo starts from one pinned `nixpkgs` input, imports it once, then layers flake inputs and local overlays on top. Everything else, packages, hosts, Home Manager, and tooling, is built from that shared package set.

For a Nix newcomer, the central idea is simple: build one package universe once, then reuse it everywhere.

## Big Picture

```text
flake.lock
  -> flake.nix inputs
    -> default.nix imports pinned nixpkgs
      -> overlays.nix
        -> mods/*
          -> pkgs/*
      -> home.nix
      -> hosts/*
        -> hosts/modules/*
      -> scripts.nix / pog / hex / snowball
```

## Pinned Base

- [`flake.lock`](https://github.com/jpetrucciani/nix/blob/main/flake.lock) pins the upstream inputs.
- [`flake.nix`](https://github.com/jpetrucciani/nix/blob/main/flake.nix) defines the public outputs for packages, hosts, dev shells, and generators.
- [`default.nix`](https://github.com/jpetrucciani/nix/blob/main/default.nix) imports `flake.inputs.nixpkgs`, injects shared inputs like `pog`, `hex`, `uv2nix`, and `poetry2nix`, then applies local overlays.

This is the central idea of the repo. Instead of importing unrelated package sets in different places, the repo builds one opinionated package universe and reuses it everywhere.

## Why Both `flake.nix` And `default.nix` Exist

This is a common point of confusion for new readers.

- `flake.nix` is the public front door. It declares inputs and publishes outputs such as packages, hosts, dev shells, and helper scripts.
- `default.nix` is the package-set constructor. It imports the pinned `nixpkgs`, injects shared inputs, and applies local overlays to produce the `pkgs` set the rest of the repo consumes.

You can read the repo as "the flake exposes things, `default.nix` builds the shared package universe those things are made from."

## One Important Definition

An overlay is just a function that receives a package set and returns additions or changes to it. In this repo, overlays are how local packages, helper abstractions, and repo-specific tools become first-class parts of `pkgs`.

## Local Overlays

- [`overlays.nix`](https://github.com/jpetrucciani/nix/blob/main/overlays.nix) is the ordered list of local overlays.
- [`mods/_pkgs.nix`](https://github.com/jpetrucciani/nix/blob/main/mods/_pkgs.nix) recursively imports `pkgs/*` and exposes those derivations at the top level.
- [`mods/pkgs/`](https://github.com/jpetrucciani/nix/tree/main/mods/pkgs) adds higher-level package families and composed outputs.
- [`mods/final.nix`](https://github.com/jpetrucciani/nix/blob/main/mods/final.nix) is the last pass for final assembly, formatter setup, and selected overrides.

## User and Machine Layers

- [`home.nix`](https://github.com/jpetrucciani/nix/blob/main/home.nix) is the main [Home Manager](/home-manager) entry point for the user environment.
- [`hosts/<name>/configuration.nix`](https://github.com/jpetrucciani/nix/tree/main/hosts) contains per-machine system configuration.
- [`hosts/common.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/common.nix) and [`hosts/common_darwin.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/common_darwin.nix) hold shared defaults.
- [`hosts/modules/*`](https://github.com/jpetrucciani/nix/tree/main/hosts/modules) contains reusable service and configuration modules that hosts import as needed.

## Host Architecture

- [`hosts/constants.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/constants.nix) defines host names, machine groups, and shared constants.
- NixOS and nix-darwin hosts live in the same repo.
- Shared modules are grouped by concern, such as `conf`, `darwin`, `exporters`, `games`, and `servers`.

## Tooling Surfaces

- [`mods/pog/*`](https://github.com/jpetrucciani/nix/tree/main/mods/pog) defines many repo-local CLI wrappers built with [`pog`](/tooling/pog).
- [`mods/hms.nix`](https://github.com/jpetrucciani/nix/blob/main/mods/hms.nix) exposes [`hms` and `hmx.<host>`](/tooling/hms-and-hmx) switch helpers.
- [`scripts.nix`](https://github.com/jpetrucciani/nix/blob/main/scripts.nix) exposes checked [script outputs](/tooling/scripts) under `.#scripts.*`.
- [`mods/snowball.nix`](https://github.com/jpetrucciani/nix/blob/main/mods/snowball.nix) packages targeted [service bundles](/tooling/snowball) for machines that are not managed as full hosts.

## Why This Layout Works

- The same overlayed package set is reused by `home.nix`, host configs, and flake outputs.
- New packages can be added under `pkgs/*` without inventing a second packaging path.
- High-level tools like `pog` and `hex` can be part of the same package universe as the systems they support.
- Readers can choose the right level: curated guide pages first, generated reference indexes second.

## If You Are Reading For The First Time

Start with [`default.nix`](https://github.com/jpetrucciani/nix/blob/main/default.nix), then [`overlays.nix`](https://github.com/jpetrucciani/nix/blob/main/overlays.nix), then one consumer such as [`home.nix`](https://github.com/jpetrucciani/nix/blob/main/home.nix) or a host config under [`hosts/`](https://github.com/jpetrucciani/nix/tree/main/hosts). That path shows the shared package set being built and then used.

## Docs Guardrails

- `nix run .#scripts.check_doc_links`
- `nix run .#scripts.check_readme_index`
- `bun run docs:gen`
- `bun run docs:build`
