# Learn Nix (Using This Repo)

Nix is a package manager and a language for describing builds, environments, and systems. This repo shows how a pinned package set can serve all three.

## Quick Vocabulary

- `nixpkgs`: the upstream collection of packages and helper functions.
- `pin`: an exact revision of an input, recorded here in `flake.lock`.
- `derivation`: a recipe for a build output, often a package.
- `overlay`: a function that adds to or changes a package set.
- `module`: a reusable configuration fragment with options and implementation.
- `flake`: a way to declare inputs and expose outputs such as packages and hosts.

## Follow One Feature

`poglets` shows the difference between a package, a module, and a host:

1. [`pkgs/server/poglets.nix`](https://github.com/jpetrucciani/nix/blob/main/pkgs/server/poglets.nix) describes how to build the binary.
2. [`mods/_pkgs.nix`](https://github.com/jpetrucciani/nix/blob/main/mods/_pkgs.nix) exposes that recipe as `pkgs.poglets`.
3. [`hosts/modules/servers/poglets.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/modules/servers/poglets.nix) defines `services.poglets` and how systemd runs the package.
4. [`hosts/neptune/configuration.nix`](https://github.com/jpetrucciani/nix/blob/main/hosts/neptune/configuration.nix) enables the service and chooses its ports.
5. `flake.nix` exposes `neptune` as `nixosConfigurations.neptune` and the package as a buildable output.

The package answers “what gets built?”, the module answers “how does it run?”, and the host answers “which machine uses it?”. The [full case study](/case-study-poglets) walks through the source and commands.

## Place That Example In The Repo

[`flake.nix`](https://github.com/jpetrucciani/nix/blob/main/flake.nix) declares inputs and creates outputs for each supported system; `flake.lock` pins their revisions. [`default.nix`](https://github.com/jpetrucciani/nix/blob/main/default.nix) constructs the package set for a system, and [`overlays.nix`](https://github.com/jpetrucciani/nix/blob/main/overlays.nix) adds local packages and tools. Hosts and Home Manager consume that package set. See [Architecture](/architecture) for the full source map.

## Try It Yourself

From the repository root, run `nix flake show --no-write-lock-file` and find both `poglets` and `neptune`. Then open the five files above and identify the build recipe, the service options, and the machine-specific values. Use [Daily Workflows](/daily-workflows) when you are ready to build either output.

## External Resources

- [nix.dev](https://nix.dev/)
- [Nix Reference Manual](https://nix.dev/manual/nix/stable/)
- [awesome-nix](https://github.com/nix-community/awesome-nix)
