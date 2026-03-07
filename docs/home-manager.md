# Home Manager

Home Manager is a user-level module system for Nix. It lets you describe packages, dotfiles, shell setup, editor configuration, and user services declaratively, then build or switch that environment from one place.

It is useful when you want your user environment to be reproducible across machines, when you want package installs and config files to come from the same source, or when `nix-env` starts feeling too ad-hoc for day-to-day use.

[`home.nix`](https://github.com/jpetrucciani/nix/blob/main/home.nix) is the main entry point into this repo's Home Manager module. If the repo is your day-to-day Nix environment, this is the file that turns the shared package set into a real user shell, toolchain, and editor setup.

## What Home Manager Covers

- User-scoped packages, instead of only system packages.
- Program configuration such as shells, editors, Git, terminals, and prompt tooling.
- Dotfiles and generated config files that should stay in sync with the package set.
- User services and session-level behavior that do not belong in a full machine config.

## Why This Repo Uses It

- It gives the repo a portable user-environment layer that is separate from NixOS host definitions.
- It is a natural place to consume the shared overlayed package set from [`default.nix`](https://github.com/jpetrucciani/nix/blob/main/default.nix).
- It turns repo-local tools and wrappers into a daily driver instead of leaving them as build-only outputs.

## What `home.nix` Does

- Reuses the same overlays as the rest of the repo with [`nixpkgs.overlays = import ./overlays.nix`](https://github.com/jpetrucciani/nix/blob/main/home.nix).
- Enables Home Manager itself and configures the core user environment.
- Installs a large set of base tools, repo-local packages, and wrapper collections.
- Switches behavior based on `machine-name`, platform, and a few environment signals.

## Why It Matters

- It is the closest thing this repo has to a daily-driver entry point.
- It proves that the package and overlay layer is not just for machine builds.
- It is where repo-specific tooling becomes something you actually live in.

## If You Mainly Want Packages

Home Manager is broad. It is great when you want package installs, program config, dotfiles, and user services to live in one declarative layer.

If your goal is narrower, mostly "give me a light way to manage reproducible packages", [`mica`](/tooling/mica) is a much smaller starting point. It focuses on package selection and managed `default.nix` files, not the full Home Manager module surface.

## What To Read In `home.nix`

- The package list in [`home.nix`](https://github.com/jpetrucciani/nix/blob/main/home.nix), to see what the repo chooses to make first-class.
- The [`mods/hms.nix`](https://github.com/jpetrucciani/nix/blob/main/mods/hms.nix) and `*_pog_scripts` additions in [`home.nix`](https://github.com/jpetrucciani/nix/blob/main/home.nix), to see how wrappers become user tools.
- The `machine-name` branching in [`home.nix`](https://github.com/jpetrucciani/nix/blob/main/home.nix), to see how one module adapts to different systems.
- The `programs.*` sections in [`home.nix`](https://github.com/jpetrucciani/nix/blob/main/home.nix), to see ordinary Home Manager configuration layered on top.

## Rebuild and Test

The repo's preferred interface is:

```bash
hms
```

For an explicit host-targeted build or switch helper, see [hms and hmx](/tooling/hms-and-hmx).

## Read Next

- [Architecture](/architecture)
- [mica](/tooling/mica)
- [Tooling](/tooling/index)
- [Daily Workflows](/daily-workflows)
