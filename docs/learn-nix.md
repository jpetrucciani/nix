# Learn Nix (Using This Repo)

Nix is both a package manager and a language for describing builds, environments, and system configuration. This repo is useful for learning it because it is not just a machine config repo. It shows how one pinned package set can become user environments, host configs, reusable modules, package overlays, and custom tools.

## Quick Vocabulary

- `nixpkgs`: the large upstream collection of packages and helper functions that most Nix projects build on.
- `pin`: an exact revision of an upstream input, used so builds stay reproducible.
- `overlay`: a function that extends or changes the package set.
- `package` or `derivation`: a build recipe and its resulting output.
- `module`: a reusable configuration fragment for a system or user environment.
- `flake`: a standard way to declare inputs and expose outputs such as packages, dev shells, and machine configs.

## Three Useful Distinctions

- A package answers, "how do I build or install this software?"
- A module answers, "how should this software or subsystem be configured?"
- A host answers, "what does this specific machine get?"

## Docs-First Reading Path

If you want the concepts before the code, read these first:

1. [Architecture](/architecture), for the shared package-set model.
2. [Home Manager](/home-manager), for the user-environment layer.
3. [Packages](/packages/index), for build recipes and package exposure.
4. [Case Study: `poglets`](/case-study-poglets), for one complete package -> module -> host walkthrough.
5. [Tooling](/tooling/index), for the repo-specific abstractions.
6. [Hosts](/hosts/index) and [Modules](/modules/index), for machine-level composition.

## What This Repo Teaches Well

- Importing a pinned `nixpkgs` once, then extending it with overlays.
- Exposing multiple flake outputs from one shared package set.
- Separating user config, machine config, reusable modules, and package recipes.
- Turning Nix code into higher-level tooling like `pog`, `hex`, and `snowball`.

## Read In This Order

Once the docs-level mental model is clear, trace the source like this:

1. **Pinned base**
   - `flake.nix`
   - `flake.lock`
   - `default.nix`
2. **Overlay assembly**
   - `overlays.nix`
   - `mods/_pkgs.nix`
   - `mods/final.nix`
3. **Daily user entry point**
   - `home.nix`
   - `mods/hms.nix`
4. **Machine layer**
   - `hosts/common.nix`
   - `hosts/common_darwin.nix`
   - `hosts/<name>/configuration.nix`
5. **Reusable system pieces**
   - `hosts/modules/*`
6. **Repo-specific tooling**
   - `mods/pog/*`
   - `examples/hex/README.md`
   - `mods/snowball.nix`

## Mental Model

Think of the repo in five layers:

1. `flake.nix` defines outputs.
2. `default.nix` imports the pinned nixpkgs input and injects shared inputs like `pog`, `hex`, and `uv2nix`.
3. `overlays.nix` composes local overlays from `mods/*`.
4. `pkgs/*`, `hosts/*`, and `home.nix` consume that overlayed package set for different jobs.
5. `mods/pog/*`, `mods/hms.nix`, `scripts.nix`, and `mods/snowball.nix` turn the package set into daily tooling.

## What To Skip At First

- Generated reference indexes, until you want an exact filename or path.
- CI and automation details, unless you are studying how the repo is validated.
- Secrets management, unless you are following host deployment and operations.

## Suggested Exercises

1. Run `nix flake show` and identify one host output, one package output, and one script output.
2. Read [Architecture](/architecture), then trace one attribute from `default.nix` to a concrete use site.
3. Build one host and one package from [Daily Workflows](/daily-workflows).
4. Read [Case Study: `poglets`](/case-study-poglets), then compare that pattern to another service or package.
5. Read [Tooling](/tooling/index), then trace either `pog`, `hex`, or `snowball` end to end.

## External Resources

- [nix.dev](https://nix.dev/)
- [Nix Reference Manual](https://nix.dev/manual/nix/stable/)
- [NixOS Wiki: Flakes](https://nixos.wiki/wiki/Flakes)
- [awesome-nix](https://github.com/nix-community/awesome-nix)
