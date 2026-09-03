# hms and hmx

`mods/hms.nix` defines the repo's preferred rebuild helpers.

These are convenience wrappers for people already using this repo day to day. If you are only exploring, the plain `nix build .#...` commands in [Daily Workflows](/daily-workflows) are the simpler starting point.

## What Gets Exposed

- `hmx.<host>`, host-specific scripts with `build`, `diff`, and `switch` actions for both NixOS and nix-darwin
  machines.
- `hms`, a helper that pulls the repo and runs one of those actions for the current machine.

Calling either script without an action is equivalent to `switch`, so existing `hms` and direct `hmx.<host>` usage keeps
working.

## Behavioral Notes

- `build` builds the system configuration and prints its store path without activating it.
- `diff` builds the system configuration, then uses `nvd diff` to show system closure changes.
- On NixOS, `diff` also runs `switch-to-configuration dry-activate` to show the systemd units and activation work that a
  switch would perform.
- On nix-darwin, `diff` also lists changed launchd plist definitions. nix-darwin does not provide an activation planner
  equivalent to NixOS `dry-activate`.
- `switch` shows the `nvd diff`, updates the system profile, and activates the configuration.
- Supports forced switching with `POG_FORCE=1`.
- On NixOS, `POG_BOOT_ONLY=1` updates the system profile but runs `switch-to-configuration boot` instead of `switch`.
- Handles both NixOS and darwin activation flows.

## Typical Usage

```bash
# build the current machine without activating it
hms build

# preview package and service changes for the current machine
hms diff

# switch the current machine using the repo's preferred helper
hms

# preview a specific host through its hmx output
$(nix build --no-link --print-out-paths --extra-experimental-features nix-command --extra-experimental-features flakes .#hmx.<host>)/bin/switch diff

# build or switch that host with the same wrapper
$(nix build --no-link --print-out-paths --extra-experimental-features nix-command --extra-experimental-features flakes .#hmx.<host>)/bin/switch build
$(nix build --no-link --print-out-paths --extra-experimental-features nix-command --extra-experimental-features flakes .#hmx.<host>)/bin/switch switch
```

## Source

- `mods/hms.nix`
- [Daily Workflows](/daily-workflows)
