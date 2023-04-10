# python

This directory provides my composable python package overlays! These are set up in a way that you can apply overlays from other repos that use mine as a source.

---

## In this directory

### [experimental.nix](./experimental.nix)

This overlay contains weird and possibly broken python packaging experiments

### [fastapi.nix](./fastapi.nix)

This overlay contains packages related to [fastapi](https://fastapi.tiangolo.com/)

### [fixes.nix](./fixes.nix)

This overlay contains fixes for current broken python packages in nixpkgs

### [hax.nix](./hax.nix)

This overlay contains interesting hax related to python packages

### [misc.nix](./misc.nix)

This overlay is for random python libraries I want in nixpkgs

### [pr.nix](./pr.nix)

This overlay is specifically for python packages [I have active PRs out for in nixpkgs proper](https://github.com/NixOS/nixpkgs/pulls?q=is%3Apr+is%3Aopen+sort%3Aupdated-desc+author%3Ajpetrucciani)

### [types.nix](./types.nix)

This overlay is specifically for type annotation libraries for python.
