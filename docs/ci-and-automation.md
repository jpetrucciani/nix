# CI and Automation

This repo uses GitHub Actions for formatting, docs validation, site deployment, builds, package publishing, and update automation.

## Main Workflows

- `check.yml`: flake evaluation, `jfmt`, docs helper checks, and the pinned, offline Vale wrapper.
- `publish_jfmt.yml` publishes the signed formatter closure and its manifest when the recipe or pins change on `main`.
- `docs.yml`: build and deploy the VitePress docs site to GitHub Pages.
- `build.yml`: evaluate every supported custom package, build the non-heavy package batch, and push it to the cache.
- `foundry.yml`: foundry image builds and registry publishing. See [foundry](/tooling/foundry) for what those outputs are.
- `update.yml`: scheduled flake input updates with PR automation.
- `update_pkgs.yml`: metadata-driven package update automation.
- `mica.yml`: publish index artifacts for mica.

## Formatter Cache

The formatter check looks up `tools/jfmt/x86_64-linux/<key>.json` on `static.g7c.us`. The key covers the shared recipe,
its flake wiring, and the lockfile. CI restores the signed closure from `cache.g7c.us` or evaluates the formatter from
the checkout.

The publisher uses the existing Nix cache secrets. For the static manifest, configure `JFMT_ENDPOINT_URL`,
`JFMT_ACCESS_KEY_ID`, and `JFMT_SECRET_ACCESS_KEY` as repository secrets. The optional
`JFMT_S3_BUCKET` repository variable defaults to `gemologic-static`. Dispatch `publish_jfmt.yml` on `main`
to backfill a manifest.

## Docs Quality Gates

Two separate docs-related checks exist in CI.

`check.yml` runs the local evaluation and docs guardrails:

```bash
nix flake check --no-build --no-write-lock-file
nix run .#scripts.check_doc_links
nix run .#scripts.check_readme_index
nix run .#scripts.check_vale
```

The Vale package includes its configured styles, so CI does not download prose-checking dependencies at runtime.

`docs.yml` builds the VitePress site itself:

```bash
cd docs
bun install --frozen-lockfile
bun run docs:build
```

## Package Evaluation and Updates

`build.yml` evaluates `lib.customPackageDrvPaths.<system>` before building packages. This catches constructor and
dependency errors in heavy packages that are intentionally excluded from `__j_custom`, without building their full
closures.

Packages opt into `update_pkgs.yml` by exposing `passthru.updateScript`. The workflow discovers the current package
list from `lib.autoUpdatePackages.x86_64-linux`, excludes packages marked with `meta.skipBuild`, and opens one update
pull request per package.

Set `passthru.skipUpdate = true` to exclude a package from automatic updates while keeping its `passthru.updateScript`
available for manual use. Packages without this flag remain eligible for automatic updates.

Third-party GitHub Actions are pinned to commit SHAs. Dependabot continues to track their version updates.

## Why This Matters

- catches docs drift and broken links early.
- proves the actual docs site still builds and deploys.
- validates key build surfaces on Linux and macOS.
- automates routine dependency/package maintenance.

## Source

- `.github/workflows/*.yml`
