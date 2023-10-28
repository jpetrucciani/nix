# pkgs

This directory contains nix packages that I've built that are not yet ready for nixpkgs proper, or that don't make sense to open as a PR to nixpkgs proper. These are broken out into individual overlays for organization

---

## In this directory

### [cli.nix](./cli.nix)

This overlay provides general CLI tools for use in text transformation and other use cases.

### [cloud.nix](./cloud.nix)

### [experimental.nix](./experimental.nix)

### [k8s.nix](./k8s.nix)

This overlay provides a handful of kubernetes related tools, like below:

##### goldilocks

[![built in go](https://img.shields.io/badge/built%20in-go-%2301ADD8)](https://go.dev/)

[Goldilocks](https://github.com/FairwindsOps/goldilocks) is a utility that can help you identify a starting point for resource requests and limits.

### [server.nix](./server.nix)

This overlay provides some servers/services as nix derivations, such as specific versions of [haproxy](http://www.haproxy.org/).

### [zaddy.nix](./zaddy.nix)

This overlay provides a [caddy web server](https://caddyserver.com/v2) builder function called `_zaddy` and a set of default plugins that you can use to build any flavor of caddy that you'd like!
