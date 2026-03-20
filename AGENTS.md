# Repository Guidelines

## Project Structure & Module Organization

- `flake.nix`, `default.nix`, `overlays.nix`, `home.nix`: core entrypoints for the flake, pinned nixpkgs, overlays, and home-manager config.
- `docs/`: VitePress docs source, including curated guides plus generated reference indexes.
- `hosts/`: per-machine NixOS and nix-darwin configs; shared bits live in `hosts/common.nix` and `hosts/common_darwin.nix`.
- `hosts/modules/`: reusable NixOS/Darwin modules grouped by domain (e.g., `servers/`, `darwin/`, `conf/`).
- `mods/`: overlays and helper modules; language-specific overlays in `mods/lang/` and `mods/python/`.
- `pkgs/`: custom packages and overlays not upstreamed to nixpkgs yet.
- `examples/` and `scripts/`: usage examples and repo helper scripts.
- `secrets/`: encrypted secrets managed with agenix (do not commit plaintext).

## Build, Test, and Development Commands

- `nix develop`: enter the dev shell (includes `jfmt` and `nixup`).
- `nix flake show`: inspect available outputs and package names.
- `nix run .#jfmt -- --ci`: run the repo formatter in CI mode.
- `nix run .#scripts.check_doc_links`: validate local markdown links.
- `nix run .#scripts.check_readme_index`: validate `README.md` directory indexes.
- `nix build .#nixosConfigurations.voyager.config.system.build.toplevel`: build a specific Linux host.
- `nix build .#darwinConfigurations.pluto.system`: build a macOS host config.
- `cd docs && bun run docs:gen`: regenerate generated docs reference pages.
- `cd docs && bun run docs:build`: build the docs site.
- `nix flake check`: run flake evaluation checks (use before PRs when possible).

## Coding Style & Naming Conventions

- Follow existing Nix formatting and structure; use two-space indentation where present.
- Run `jfmt` for Nix formatting when touching Nix files.
- JavaScript/Markdown should match `prettier.config.js` (2-space indent, 120 columns).
- Module and package files use descriptive, lowercase names (e.g., `hosts/modules/servers/minifluxng.nix`).

## Testing Guidelines

- There is no dedicated test suite yet; rely on docs checks, targeted `nix build`, and `nix flake check` for the affected host/module.
- When adding packages, prefer a local build of that derivation to validate dependencies.
- When touching docs or READMEs, run `nix run .#scripts.check_doc_links`, `nix run .#scripts.check_readme_index`, and regenerate/build the docs site when needed.

## Commit & Pull Request Guidelines

- Commit messages are short and imperative; recent history often uses patterns like `automatic update ...` or `update <area>`.
- Keep commits scoped (one host/module per change when reasonable).
- PRs should describe the affected hosts/modules, list the commands run, and note any manual validation.
- Never include decrypted secrets; updates must stay within `secrets/*.age` and `secrets/secrets.nix`.

## Security & Configuration Notes

- Secrets are encrypted with agenix; see `secrets/README.md` for workflow details.
- Host lists and shared constants live in `hosts/constants.nix`; update there when adding machines.
