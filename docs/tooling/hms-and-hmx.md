# hms and hmx

`mods/hms.nix` defines the repo's preferred rebuild helpers.

These are convenience wrappers for people already using this repo day to day. If you are only exploring, the plain `nix build .#...` commands in [Daily Workflows](/daily-workflows) are the simpler starting point.

## What Gets Exposed

- `hmx.<host>`, host-specific `switch` scripts for both NixOS and nix-darwin machines.
- `hms`, a helper that pulls the repo and switches the current machine.

Here, `switch` means "build the configuration and activate it on the machine".

## Behavioral Notes

- Uses `nvd diff` before switching.
- Supports forced switching with `POG_FORCE=1`.
- Handles both NixOS and darwin activation flows.

## Typical Usage

```bash
# switch the current machine using the repo's preferred helper
hms

# build and run a specific host switch output directly
$(nix build --no-link --print-out-paths --extra-experimental-features nix-command --extra-experimental-features flakes .#hmx.<host>)/bin/switch
```

## Source

- `mods/hms.nix`
- [Daily Workflows](/daily-workflows)
