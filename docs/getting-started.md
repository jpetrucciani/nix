# Getting Started

This site is for people who want to understand how this repo uses Nix, steal ideas from it, or safely poke around without reverse-engineering the tree first.

If words like `flake`, `overlay`, `module`, or `derivation` are still fuzzy, start with [Learn Nix](/learn-nix) before you start tracing source files.

## Read This First

If you only read four pages, make it these:

1. [Learn Nix](/learn-nix), for the repo-shaped learning path.
2. [Architecture](/architecture), for the pinned-base plus overlay model.
3. [Home Manager](/home-manager), for the daily user-environment entry point.
4. [Tooling](/tooling/index), for `pog`, `hex`, `snowball`, and the repo-local helpers.

## Prerequisites

- Nix installed. This repo uses flakes for most build and discovery commands.
- Git available locally.
- Access to this repository.

## Clone and Enter

```bash
git clone https://github.com/jpetrucciani/nix.git ~/cfg
cd ~/cfg
nix develop
```

If you only want to read the tree and skim the outputs, you can skip `nix develop`.

## First Commands

```bash
nix flake show
```

This is the fastest way to see the flake outputs the repo exposes.

Then run a few safe checks and builds:

```bash
# formatting and docs checks used by this repo
nix run .#jfmt -- --ci
nix run .#scripts.check_doc_links
nix run .#scripts.check_readme_index

# linux host example
nix build .#nixosConfigurations.voyager.config.system.build.toplevel

# darwin host example
nix build .#darwinConfigurations.pluto.system

# package example
nix build .#zaddy
```

## If You Want To Explore By Topic

- Machine configs: [Hosts](/hosts/index) and [Modules](/modules/index)
- User environment: [Home Manager](/home-manager)
- Package-focused setup: [mica](/tooling/mica)
- Image and container builders: [foundry](/tooling/foundry)
- Package layer: [Packages](/packages/index)
- Repo-specific tools: [Tooling](/tooling/index)
- Operational commands: [Daily Workflows](/daily-workflows)

## What To Ignore On A First Pass

- The generated [Reference](/reference/index) section, unless you need an exact path.
- CI workflow details, unless you want to understand how the repo is checked or published.
- Secrets management, unless you are studying host deployment or operations.

## Next Pages

- [Learn Nix](/learn-nix)
- [Case Study: `poglets`](/case-study-poglets)
- [Architecture](/architecture)
- [Home Manager](/home-manager)
- [Tooling](/tooling/index)
