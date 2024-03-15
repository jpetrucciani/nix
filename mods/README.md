# mods

This directory contains my overlays for nixpkgs, but configured in a way that others can reuse specific parts of my overlays if they'd like to use this repo as a source.

---

## In this directory

### [lang/](./lang/)

This directory contains package sets for specific languages that I overlay functionality on top of, like [vlang](https://vlang.io/) and [nim](https://nim-lang.org)

### [pkgs/](./pkgs/)

This directory contains nix packages that I've built that are not yet ready for nixpkgs proper, or that don't make sense to open as a PR to nixpkgs proper

### [pog/](./pog/)

This directory contains overlays containing tools with my [`pog`](./pog.nix) module! The pog module can create powerful, best practices CLI tools.

### [python/](./python/)

This directory provides my python package overlays.

### [bashbible.nix](./bashbible.nix)

This overlay contains the bashbible implemented entirely in nix attr sets.

### [containers.nix](./containers.nix)

this overlay injects [nix2container](https://github.com/nlewo/nix2container) into scope

### [fake_platform.nix](./fake_platform.nix)

This overlay allows us to fake the build platform to attempt to build packages on unsupported OSes.

### [final.nix](./final.nix)

This overlay acts as the last overlay, allowing me to add attributes after every other overlay in this repo

### [foundry.nix](./foundry.nix)

This overlay provides a way to build foundry docker images with nix

### [hashers.nix](./hashers.nix)

This overlay provides shorthand commands for generating rev/sha256 combos for common repos I touch.

### [hax.nix](./hax.nix)

This overlay provides the `hax` library, which contains useful functions and other packages and configurations.

### [hms.nix](./hms.nix)

This overlay provides more packages and scripts for use in my setup. This is also used in my repo's modified comma, exposing the binaries and scripts in this overlay directly through comma.

### [lang.nix](./lang.nix)

This overlay provides new helpers for programming languages (like [vlang](https://vlang.io/) and [nim](https://nim-lang.org)). These helpers provide a default set of packages, and a way to build environments that link these packages into the build environment.

### [override.nix](./override.nix)

This overlay provides some overrides/fixes for various packages

### [\_pkgs.nix](./_pkgs.nix)

This overlay allows me to load the custom packages I've built in my [pkgs/](../pkgs/) directory

### [pog.nix](./pog.nix)

This overlay provides the `pog` function, as well as a good amount of constants that make building tools easier.
