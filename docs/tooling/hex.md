# hex

[`hex`](https://hex.gemologic.dev/) is a Nix-driven configuration and rendering workflow. In this repo it is mainly important as a way to express Kubernetes-oriented specs and render them from Nix rather than hand-maintaining YAML.

## How This Repo Uses It

- `default.nix` imports `hex`, `hexcast`, and `nixrender` into the shared package set.
- `examples/hex/README.md` shows the local example flow.
- `mods/pog/nix.nix` exposes `hex` and `hexcast` as part of the repo's `nix`-oriented tool surface.

## Why It Matters Here

- It shows that this repo is not only about packaging software.
- It demonstrates using Nix as a higher-level source language for other systems.
- It pairs naturally with `pog`, because the repo can ship the tools and the ergonomics together.

## Local Starting Points

- `examples/hex/README.md`
- `examples/hex/charts.nix`
- `examples/hex/default.nix`

## Read Next

- [pog](/tooling/pog)
- [snowball](/tooling/snowball)
