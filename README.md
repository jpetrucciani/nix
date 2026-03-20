# jpetrucciani/nix

[![uses nix](https://img.shields.io/badge/uses-nix-%237EBAE4)](https://nixos.org/)

_jacobi's pinned nixpkgs setup, layered overlays, custom packages, host configs, and repo-specific tooling_

## Start Here

The best entry point is the curated docs [hosted here!](https://nixdocs.cobi.dev/) (or source found under [`docs/`](./docs/)). If you are new to the repo, read these first:

1. [`docs/getting-started.md`](./docs/getting-started.md)
2. [`docs/architecture.md`](./docs/architecture.md)
3. [`docs/home-manager.md`](./docs/home-manager.md)
4. [`docs/tooling/index.md`](./docs/tooling/index.md)

If you want to make a safe change:

1. Enter the dev shell with `nix develop`.
2. Inspect the exposed outputs with `nix flake show`.
3. Pick an area:
   - hosts and machine configs: [`hosts/README.md`](./hosts/README.md)
   - overlays and helpers: [`mods/README.md`](./mods/README.md)
   - package definitions: [`pkgs/README.md`](./pkgs/README.md)
   - scripts and automation helpers: [`scripts/README.md`](./scripts/README.md)
4. Run the docs and formatting guardrails:
   - `nix run .#jfmt -- --ci`
   - `nix run .#scripts.check_doc_links`
   - `nix run .#scripts.check_readme_index`
5. Build the thing you touched:
   - Linux host: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
   - Darwin host: `nix build .#darwinConfigurations.<host>.system`
   - Package: `nix build .#<package-name>`

## Repo Map

### [docs/](./docs/)

VitePress source for the repo docs, including curated guides plus generated reference indexes.

### [hosts/](./hosts/)

Concrete NixOS and nix-darwin machine definitions, shared host defaults, and reusable host modules.

### [mods/](./mods/)

The local overlay layer. This is where higher-level helper surfaces like `pog`, `foundry`, `snowball`, and Python overlay families are assembled.

### [pkgs/](./pkgs/)

Custom derivations grouped by area such as `cli`, `cloud`, `server`, `mcp`, and `uv`.

### [scripts/](./scripts/)

Repository helpers, bootstrap scripts, and static support files. Checked script outputs also live in [`scripts.nix`](./scripts.nix) and are exposed as `.#scripts.*`.

### [secrets/](./secrets/)

Encrypted secret material managed with [agenix](https://github.com/ryantm/agenix).

### [examples/](./examples/)

Small examples that show how to consume pieces of this repo directly.

## Notable Surfaces

### [pog](https://pog.gemologic.dev/)

[`pog`](./docs/tooling/pog.md) is the repo's CLI-wrapper workhorse. The concrete wrapper families live under [`mods/pog/`](./mods/pog/).

### [hex](https://hex.gemologic.dev/)

[`hex`](./docs/tooling/hex.md) is used here as a Nix-native spec and render workflow, especially for Kubernetes-shaped configuration.

### [foundry](./docs/tooling/foundry.md)

The shared image-building surface for cloud images, installer media, and task-focused container images.

### [mica](./docs/tooling/mica.md)

A lighter package-focused environment manager that complements the broader Home Manager setup in [`home.nix`](./home.nix).

### [hms and hmx](./docs/tooling/hms-and-hmx.md)

Convenience rebuild and switch helpers for day-to-day use on repo-managed machines.

## Core Files

### [flake.nix](./flake.nix)

The public flake entry point. It declares inputs and exposes packages, dev shells, hosts, image builders, and helper outputs.

### [default.nix](./default.nix)

Builds the shared package universe from the pinned `nixpkgs` input plus the local overlay stack.

### [overlays.nix](./overlays.nix)

Orders and applies the overlays from [`mods/`](./mods/).

### [home.nix](./home.nix)

The main Home Manager entry point for the daily user environment.

## Useful References

### [awesome-nix](https://github.com/nix-community/awesome-nix)

A curated list of the best resources in the Nix community.

### [nix.dev](https://nix.dev/)

Official documentation for getting things done with Nix. ([source repo here](https://github.com/NixOS/nix.dev))

### [keith's nix repo](https://github.com/kwbauson/cfg)

[Keith](https://github.com/kwbauson/) is a friend of mine and is the person who first introduced me to nix - his repo has been a great thing to explore to learn more about what is possible.

### [wuz's nix repo](https://github.com/wuz/prst)

[wuz](https://github.com/wuz) is a friend of mine who has some great nix modules/examples! Wuz has many examples of fully configuring things with [home-manager](https://github.com/nix-community/home-manager).

### [how to learn nix](https://ianthehenry.com/posts/how-to-learn-nix/)

an awesome blog series by [Ian Henry](https://twitter.com/ianthehenry) about learning nix.

### [nix package search](https://search.nixos.org/packages?channel=unstable)

This is the official nixpkgs search engine. I use this all the time!

### [nix-learning](https://github.com/humancalico/nix-learning)

This is a collection of other resources that are useful for getting a better understanding of nix.
