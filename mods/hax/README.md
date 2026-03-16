# hax

This directory holds helper source files that support the `hax` overlay in [`../hax.nix`](../hax.nix).

These files are not a separate public overlay layer on their own. They are implementation details that back the broader `pkgs.hax` helper surface.

---

## In this directory

### [docker.nix](./docker.nix)

This is a customized Docker image builder derived from the upstream Nix helper, with extra tools, user handling, and Nix bootstrap behavior that fit this repo's workflows.
