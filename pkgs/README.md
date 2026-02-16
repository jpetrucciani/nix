# pkgs

This directory contains nix packages that I've built that might not be yet ready for nixpkgs proper, or that don't make sense to open as a PR to nixpkgs proper. They are included as the reference `.#custom`, and also are merged into the `pkgs` set.

---

## In this directory

### [ai/](./ai/)

This directory contains packages that are related to the new wave of AI/LLM popularity!

### [cli/](./cli/)

This directory contains various cli tools

### [cloud/](./cloud/)

This directory contains tooling related to various cloud providers

### [k8s/](./k8s/)

This directory contains tools related to kubernetes

### [lib/](./lib/)

This directory contains derivations that are just libraries for other derivations

### [misc/](./misc/)

This is a catch-all directory, for anything that doesn't fit nicely into other directories

### [prometheus/](./prometheus/)

This directory contains prometheus exporters

### [server/](./server/)

This directory contains specific servers

### [uv/](./uv/)

This directory contains apps built with uv2nix using my wrapper
