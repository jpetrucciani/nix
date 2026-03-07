# pog

[`pog`](https://pog.gemologic.dev/) is a CLI wrapper generator built with Nix. In this repo it is one of the main reasons the package layer feels ergonomic instead of austere.

## How This Repo Uses It

- `default.nix` imports `pog` into the shared package set.
- `mods/pog/*.nix` defines domain-specific command collections.
- `home.nix` installs many of those generated command sets directly into the user environment.

## High-Value Areas

- `mods/pog/aws.nix`
- `mods/pog/gcp.nix`
- `mods/pog/k8s.nix`
- `mods/pog/docker.nix`
- `mods/pog/general.nix`
- `mods/pog/nix.nix`

## Why It Fits Here

- The generated CLIs share flags, completion behavior, and help output.
- Repetitive shell snippets become versioned Nix code instead of dotfile trivia.
- Repo-local operational workflows stay close to the package and host definitions they support.

## Read Next

- [Tooling Overview](/tooling/index)
- [hex](/tooling/hex)
- [hms and hmx](/tooling/hms-and-hmx)
