# mica

[`mica`](https://github.com/gemologic/mica) is a TUI and CLI for managing Nix environments. It lets you search packages, apply presets, and keep a managed `default.nix` with much less manual Nix editing.

## Why It Matters Here

- This repo packages `mica` at `pkgs/cli/mica.nix`, so it is available as part of the same pinned package set.
- It fits the repo's broader goal of making Nix more ergonomic.
- It is a good on-ramp for people who want reproducible package environments before they are ready for a full Home Manager setup.

## A Lightweight Alternative To Home Manager, For Packages

Home Manager is the larger tool. It manages packages, program configuration, dotfiles, and user services through a module system.

`mica` is narrower. It focuses on package selection, presets, and managed environment files. If you mostly want "search packages, pick a few, save a reproducible environment", it is a lighter place to start.

That makes it a useful complement to this repo:

- Use [Home Manager](/home-manager) when you want the full user-environment layer.
- Use `mica` when you mainly want a convenient package manager for project or global environments.

## How To Install It From This Repo

Install it directly from the archive form of this repo:

```bash
nix-env -f https://github.com/jpetrucciani/nix/archive/main.tar.gz -iA mica
```

Or run it once through the flake output:

```bash
nix run github:jpetrucciani/nix#mica -- --global
```

Because this repo exports `mica` as a package, you can also use `mica` itself to add `mica` into the global environment it manages. That gives you a small bootstrap path: run it once, then let it manage its own future installation as part of the global package set.

## Typical Uses

- `mica init`, create a managed `default.nix` for a project.
- `mica tui`, launch the package-search TUI.
- `mica --global list`, inspect the global package state.
- `mica --global add ripgrep fd`, add a couple of packages globally.

## Read Next

- [Home Manager](/home-manager)
- [Packages](/packages/index)
- [Tooling Overview](/tooling/index)
