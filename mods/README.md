# mods

This directory contains my overlays for nixpkgs, but is set up in a way that others can reuse specific parts of my overlays if they'd like to use this repo as a source.

---

## In this directory

### [lang/](./lang/)

This directory contains package sets for specific languages that I overlay functionality on top of, like [vlang](https://vlang.io/) and [nim](https://nim-lang.org)

### [pkgs/](./pkgs/)

This directory contains nix packages that I've built that are not yet ready for nixpkgs proper, or that don't make sense to open as a PR to nixpkgs proper. These are broken out into individual overlays for organization

### [pog/](./pog/)

This directory contains overlays that implement tools with my [`pog`](./pog.nix) module! The pog module can be used to create very powerful, best practices CLI tools in an easy way.

### [python/](./python/)

This directory provides my python package overlays.

### [bashbible.nix](./bashbible.nix)

This overlay contains the bashbible implemented entirely in nix attr sets.

### [custom_pkgs.nix](./custom_pkgs.nix)

This overlay allows me to load the custom packages I've build in my [pkgs/](../pkgs/) directory

### [fake_platform.nix](./fake_platform.nix)

This overlay allows us to fake the build platform to attempt to build packages on OSes that may not be supported.

### [hashers.nix](./hashers.nix)

This overlay provides shorthand commands for generating rev/sha256 combos for common repos I touch.

### [hax.nix](./hax.nix)

This overlay provides the `hax` library, which contains a number of useful functions and other packages and configurations.

### [lang.nix](./lang.nix)

This overlay provides new helpers for a few programming languages (like [vlang](https://vlang.io/) and [nim](https://nim-lang.org)). These helpers provide a default set of packages, and a way to easily build environments that link these packages into the build environment.

### [mods.nix](./mods.nix)

This overlay provides many more packages and scripts for use in my setup. This is also used in my repo's modified comma, exposing the binaries and scripts in this overlay directly through comma.

### [pog.nix](./pog.nix)

This overlay provides the `pog` function, as well as a good amount of constants that make building tools easier.
