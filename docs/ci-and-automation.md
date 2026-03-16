# CI and Automation

This repo uses GitHub Actions for formatting, builds, linting, package publishing, and update automation. The docs site itself is separate from those repo checks, but it uses the same source tree and benefits from the same link and docs-policy scripts.

## Main Workflows

- `check.yml`: `jfmt`, docs checks, `vale`.
- `build.yml`: cross-platform package builds and cache push.
- `foundry.yml`: foundry image builds and registry publishing. See [foundry](/tooling/foundry) for what those outputs are.
- `update.yml`: scheduled flake input updates with PR automation.
- `update_pkgs.yml`: targeted package update automation.
- `mica.yml`: publish index artifacts for mica.

## Docs Quality Gates

`check.yml` runs:

```bash
nix run .#scripts.check_doc_links
nix run .#scripts.check_readme_index
```

For the VitePress site itself, use:

```bash
cd docs
bun run docs:gen
bun run docs:build
```

## Why This Matters

- catches docs drift and broken links early.
- validates key build surfaces on Linux and macOS.
- automates routine dependency/package maintenance.

## Source

- `.github/workflows/*.yml`
