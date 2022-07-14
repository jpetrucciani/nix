# mods

This directory contains my overlays for nixpkgs, but is set up in a way that others can reuse specific parts of my overlays if they'd like to use this repo as a source.

---

## In this directory

### [caddy.nix](./caddy.nix)

This overlay provides a [caddy webserver](https://caddyserver.com/v2) builder function and a set of default plugins that you can use to build any flavor of caddy that you'd like!

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

### [pkgs.nix](./pkgs.nix)

This overlay provides a few more custom packages that can be included in my version of better-comma.

### [python_pkgs.nix](./python_pkgs.nix)

This overlay provides my python package overrides.
