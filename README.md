# jpetrucciani/nix

[![uses nix](https://img.shields.io/badge/uses-nix-%237EBAE4)](https://nixos.org/)

_jacobi's nixpkgs configurations, overlays, documentation, and other magic_

# interesting stuff

## [pog](https://pog.gemologic.dev/)

_note: this has moved to it's [own repo!](https://github.com/jpetrucciani/hex)_

This set of nix functions has proven to be extremely useful to me - it is a quick CLI tool generator that leverages the power of nix!

[See many examples of how it can be used here!](./mods/pog/) Some fun files/examples to look at:

- [aws - lots of goodies for simplifying interacting with AWS. check out the `ec2_spot_interrupt`!](./mods/pog/aws.nix)
- [dtools - docker wrapper cli tools that make it easier to interact with docker](./mods/pog/docker.nix)
- [ffmpeg - tired of trying to remember that arcane ffmpeg invocation? wrap it in pog!](./mods/pog/ffmpeg.nix)
- [ktools - kubectl wrapper cli tools that make it easier to interact with clusters and their resources](./mods/pog/k8s.nix)

## [hex](https://hex.gemologic.dev/)

_note: this has moved to it's [own repo!](https://github.com/jpetrucciani/hex)!_

Hex is a nix module system that allows us to create powerful abstractions of other languages and configurations via nix! At the moment, this is the most useful for things like [kubernetes specs](https://kubernetes.io/docs/concepts/overview/working-with-objects/)!

Check out [the hex repo](https://github.com/jpetrucciani/hex) for more context on what this can do, and how to use it!

## [pkgs](./pkgs/)

This directory contains custom top level packages that I maintain. These will resemble packages that are stored in nixpkgs directly, and are exposed at the top level of `pkgs` inside my flake/module.

## [python packages](./mods/python/)

I maintain a large number of nix python packages that are available as overlays from this repo!

## [zaddy](./mods/pkgs/zaddy.nix)

This is a custom build system for the [caddy](https://caddyserver.com/) web server that supports including caddy plugins as part of nix derivations! You can build your own (check out the examples in that module), or use one of my presets `zaddy` (caddy with [caddy-security](sha256-ww1mWXRKD53S8ytFbyKGn7vXZ5rJjvjOFQpdeDWJz4c=), an s3 proxy, geoip blocking, some of my own plugins, etc.) and `zaddy-browser` (just caddy-security and s3 plugins). I also maintain a list of popular plugins that can be included in your build.

## directories

#### [.github/](./.github/)

This directory contains my GitHub actions, which automatically check for updates to various sources, and rebuild and cache my nix setups for various platforms.

#### [examples/](./examples/)

This directory contains examples of use of my repo as a source for other tools/environments!

#### [hosts/](./hosts/)

This directory contains my NixOS configurations for each of my NixOS machines, as well as a `common.nix` file that contains shared configurations for my servers/clients.

#### [mods/](./mods/)

This directory contains my overlays for nixpkgs, but configured in a way that others can reuse specific parts of my overlays if they'd like to use this repo as a source.

#### [pkgs/](./pkgs/)

This directory contains nix packages that I've built that might not be yet ready for nixpkgs proper, or that don't make sense to open as a PR to nixpkgs proper.

#### [scripts/](./scripts/)

This directory contains various random scripts that I use in this repo, or in packages created by this repo.

#### [secrets/](./secrets/)

This directory contains encrypted secrets for my nixos machines, using [agenix](https://github.com/ryantm/agenix).

#### [default.nix](./default.nix)

This file acts as the entrypoint for nix to pin my nixpkgs version to the rev and sha256 found [in the flake.lock](./flake.lock).

#### [flake.nix](./flake.nix)

My main [nix flake](https://nixos.wiki/wiki/Flakes) file

#### [home.nix](./home.nix)

This file contains my main [home-manager](https://github.com/nix-community/home-manager) configuration. This includes all sorts of packages, configurations, and dotfiles for pretty much all software that I use.

#### [overlays.nix](./overlays.nix)

This file declares the overlays that I apply to my pinned version of nixpkgs. This should load the files in the [mods](./mods/) directory, which are overlay functions which apply to my nixpkgs object in nix. **note that this file is much more verbose than required! personally, I prefer the explicitness here**

---

# other great resources

## [awesome-nix](https://github.com/nix-community/awesome-nix)

A curated list of the best resources in the Nix community.

## [nix.dev](https://nix.dev/)

Official documentation for getting things done with Nix. ([source repo here](https://github.com/NixOS/nix.dev))

## [keith's nix repo](https://github.com/kwbauson/cfg)

[Keith](https://github.com/kwbauson/) is the person who first introduced me to nix - his repo has been a great thing to explore to learn more about what is possible.

## [how to learn nix](https://ianthehenry.com/posts/how-to-learn-nix/)

an awesome blog series by [Ian Henry](https://twitter.com/ianthehenry) about learning nix.

## [nix package search](https://search.nixos.org/packages?channel=unstable)

This is the official nixpkgs search engine. I use this all the time!

## [nix-learning](https://github.com/humancalico/nix-learning)

This is a collection of other resources that are useful for getting a better understanding of nix.
