# Script Outputs

`scripts.nix` defines checked shell-script outputs that are exposed as flake outputs.

In plain terms, that means the repo publishes small runnable utilities at paths like `.#scripts.check_doc_links`, and Nix can build or run them just like packages.

## Why This Pattern Exists

- Shell scripts are validated at build time with `writeBashBinChecked`.
- Scripts become reproducible outputs instead of ad-hoc repository helpers.
- CI and local users can run the same commands through `nix run .#scripts.<name>`.
- The README index checker validates manual `## In this directory` inventories across the repo.

## Important Examples

- `scripts.check_doc_links`
- `scripts.check_readme_index`
- `scripts.ci_cache`

## Typical Usage

```bash
nix run .#scripts.check_doc_links
nix run .#scripts.check_readme_index
```

## Source

- `scripts.nix`
- [Generated Script Index](/reference/generated-scripts)
