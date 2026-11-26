# scripts

Git branch cleanup and Nix bootstrap scripts.

Docs validation helpers are defined in [`../scripts.nix`](../scripts.nix) as `writeBashBinChecked` derivations and exposed as `.#scripts.*` flake outputs.

---

## In this directory

### [git-trim.sh](./git-trim.sh)

This script allows us to trim the git branches.

### [nixup.sh](./nixup.sh)

This script is a shorthand to load up nix (on non-nixos linux, windows with WSL2, or mac) and configure some basic things. You can run this by doing:

```bash
curl -L https://cobi.dev/nixup | bash
```

### [files/](./files/)

supporting static files used by scripts and host bootstrap flows.
