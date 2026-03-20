# CI and Automation

This repo uses GitHub Actions for formatting, docs validation, site deployment, builds, package publishing, and update automation.

## Main Workflows

- `check.yml`: `jfmt`, docs helper checks, `vale`.
- `docs.yml`: build and deploy the VitePress docs site to GitHub Pages.
- `build.yml`: cross-platform package builds and cache push.
- `foundry.yml`: foundry image builds and registry publishing. See [foundry](/tooling/foundry) for what those outputs are.
- `update.yml`: scheduled flake input updates with PR automation.
- `update_pkgs.yml`: targeted package update automation.
- `mica.yml`: publish index artifacts for mica.

## Docs Quality Gates

Two separate docs-related checks exist in CI.

`check.yml` builds and runs the local docs guardrails:

```bash
nix run .#scripts.check_doc_links
nix run .#scripts.check_readme_index
```

`docs.yml` builds the VitePress site itself:

```bash
cd docs
bun install
bun run docs:gen
bun run docs:build
```

## Why This Matters

- catches docs drift and broken links early.
- proves the actual docs site still builds and deploys.
- validates key build surfaces on Linux and macOS.
- automates routine dependency/package maintenance.

## Source

- `.github/workflows/*.yml`
