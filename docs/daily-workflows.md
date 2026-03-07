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
