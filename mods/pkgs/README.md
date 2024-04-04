# pkgs

This directory contains nix packages that I've built that are not yet ready for nixpkgs proper, or that don't make sense to open as a PR to nixpkgs proper. These are broken out into individual overlays for organization. **These are not built automatically in CI!**

---

## In this directory

### [ai.nix](./ai.nix)

ai related experimental packages!

### [cli.nix](./cli.nix)

This overlay provides general CLI tools for use in text transformation and other use cases.

### [cloud.nix](./cloud.nix)

cloud related experimental tools

### [experimental.nix](./experimental.nix)

extra experimental packages

### [k8s.nix](./k8s.nix)

This overlay provides a handful of kubernetes related tools

### [server.nix](./server.nix)

This overlay provides some servers/services as nix derivations, such as specific versions of [haproxy](http://www.haproxy.org/).

### [webapp.nix](./webapp.nix)

experimental webapps

### [zaddy.nix](./zaddy.nix)

This overlay provides a [caddy web server](https://caddyserver.com/v2) builder function called `_zaddy` and a set of default plugins that you can use to build any flavor of caddy that you'd like!
