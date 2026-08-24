# Daily Workflows

This page is the short operational guide for trying the repo locally. It is intentionally practical.

## Explore Outputs

```bash
nix flake show
```

## Rebuild the Current Machine

If your local setup has `hms` available:

```bash
hms
```

Equivalent behavior is defined in `mods/hms.nix`.

Here, "switch" means "build the configuration and activate it on the target machine".

## Build or Switch a Specific Host

```bash
# build explicit host switch helper
nix build --no-link --print-out-paths --extra-experimental-features nix-command --extra-experimental-features flakes .#hmx.<host>

# run switch binary
$(nix build --no-link --print-out-paths --extra-experimental-features nix-command --extra-experimental-features flakes .#hmx.<host>)/bin/switch
```

## Build a Host Without Switching

```bash
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
nix build .#darwinConfigurations.<host>.system
```

## Build a Package

```bash
nix build .#<package-name>
```

Examples:

```bash
nix build .#zaddy
nix build .#llama-cpp-latest
```

## Inspect and Test the Local Overlay Delta

Compare every top-level attribute declared by the local overlay stack with the exact `nixpkgs` revision in
`flake.lock`:

```bash
nix run .#overlay-diff
nix run .#overlay-diff -- --overrides
nix run .#overlay-diff -- --json
```

For one overridden derivation, compare its derivation closure with the pinned upstream derivation:

```bash
nix run .#ndiff -- bkt
```

Build only named attributes from that manifest:

```bash
nix run .#overlay-check -- bkt concurrently caddy
```

Use `--dry-run` to inspect the build plan. `--all` builds every supported, non-broken package discovered under
`pkgs/`; packages with `meta.skipBuild = true` stay out of that batch.

The flake exposes this focused derivation set under `packages`, and keeps the complete overlayed nixpkgs universe
under `legacyPackages`. Normal commands such as `nix build .#bun` still fall back to `legacyPackages`.

## Regenerate and Preview Docs

```bash
cd docs
bun run docs:gen
bun run docs:dev
```

## Run Repo Checks

```bash
nix run .#jfmt -- --ci
nix run .#scripts.check_doc_links
nix run .#scripts.check_readme_index
```

## Read More About the Helpers

- [hms and hmx](/tooling/hms-and-hmx)
- [pog](/tooling/pog)
- [scripts outputs](/tooling/scripts)
