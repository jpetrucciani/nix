# ocaml

This directory contains OCaml-specific overlay logic.

The current focus here is keeping the Dream stack and its transitive dependencies buildable together, including a few version pins and Darwin-specific fixes that do not fit cleanly in the generic overlay files.

---

## In this directory

### [default.nix](./default.nix)

This overlay overrides pieces of `ocamlPackages`, adds the Dream-related packages this repo needs, and applies compatibility fixes for older `httpun` and `h2` versions plus a few Darwin packaging tweaks.
