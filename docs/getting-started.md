# Getting Started

This page gets you from a clone to an understanding of the outputs this repo exposes. You can inspect the repo without building a machine or switching your system.

If `flake`, `overlay`, or `module` is unfamiliar, read [Learn Nix](/learn-nix) for a short example before tracing the source.

## Prerequisites

- Nix with flakes enabled.
- Git.
- A supported system for local builds: `x86_64-linux`, `aarch64-linux`, or `aarch64-darwin`.

## Clone and Inspect

```bash
git clone https://github.com/jpetrucciani/nix.git ~/cfg
cd ~/cfg
nix eval --raw --impure --expr builtins.currentSystem
nix flake show --no-write-lock-file
```

Find your system in the flake output, then pick one package or host name to trace. Package recipes live under `pkgs/` or `mods/pkgs/`, while host outputs come from the lists in `hosts/constants.nix`. A host build is a separate, usually much larger step.

Enter the development shell when you want the repo's formatters and helper tools:

```bash
nix develop
```

## Choose a Next Task

- To understand how the files fit together, read [Architecture](/architecture) and the [`poglets` case study](/case-study-poglets).
- To build a package or preview a host change, use [Daily Workflows](/daily-workflows).
- To explore the user environment, read [Home Manager](/home-manager).
- To find an exact source path, use the [generated reference](/reference/index).
