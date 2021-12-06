# mods

This directory contains my overlays for nixpkgs, but is set up in a way that others can reuse specific parts of my overlays if they'd like to use this repo as a source.

---

## [custom_pkgs.nix](./custom_pkgs.nix)

This overlay allows me to load the custom packages I've build in my [pkgs/](../pkgs/) directory

## [fake_platform.nix](./fake_platform.nix)

This overlay allows us to fake the build platform to attempt to build packages on OSes that may not be supported.

## [hashers.nix](./hashers.nix)

This overlay provides shorthand commands for generating rev/sha256 combos for common repos I touch.

## [hax.nix](./hax.nix)

This overlay provides the `hax` library, which contains a number of useful functions and other packages and configurations.

## [mods.nix](./mods.nix)

This overlay provides many more packages and scripts for use in my setup. This is also used in my repo's modified comma, exposing the binaries and scripts in this overlay directly through comma.

## [python_pkgs.nix](./python_pkgs.nix)

This overlay provides my python package overrides.
