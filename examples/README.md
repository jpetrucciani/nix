# examples

This directory contains examples of use of my repo as a source for other tools/environments!

## How to use

Drop a file like this in your home directory (`~/cfg.nix`) and run `nix-env -i -f ~/cfg.nix to use this file to manage your globally installed nix packages!

Or, alternatively, use a similar setup within a project directory to create a reproducible environment for that directory!

```bash
# use nixup for an easy way to bootstrap a default.nix!
nixup --with_python --with_db_pg >./default.nix
echo "use nix" >.envrc
direnv allow
```

---

## In this directory

### [cfg.nix](./cfg.nix)

This file contains an example of a lightweight `cfg.nix` file for configuring a global environment on a non-nixOS system.
