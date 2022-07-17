# pkgs

This directory contains package sets for specific languages that I overlay functionality on top of, like [vlang](https://vlang.io/) and [nim](https://nim-lang.org)

---

## In this directory

### [nim-packages.nix](./nim-packages.nix)

This derivation contains a chunk of popular packages from [nim's nimble package directory](https://nimble.directory/). It is referenced by `nim.withPackages`

### [v-packages.nix](./v-packages.nix)

This derivation contains a chunk of popular packages from [vlang's vpm package manager](https://vpm.vlang.io/). It is referenced by `vlang.withPackages`
