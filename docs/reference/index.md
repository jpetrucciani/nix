# Reference

This section is the generated index layer for large or fast-moving parts of the repo. The guide pages elsewhere in the site are curated and explanatory. These pages are the exact inventories.

If you are new to the repo or to Nix, you can safely skip this section at first. It is a map, not a tutorial.

The generated indexes come from [`docs/scripts/generate-docs.mjs`](https://github.com/jpetrucciani/nix/blob/main/docs/scripts/generate-docs.mjs).

Run the generator from `docs/`:

```bash
bun run docs:gen
```

## Generated Indexes

1. [Generated Host Index](/reference/generated-hosts)
2. [Generated Module Index](/reference/generated-modules)
3. [Generated Package Index](/reference/generated-packages)
4. [Generated Wrapper Index](/reference/generated-wrappers)
5. [Generated Script Index](/reference/generated-scripts)
6. [Generated Workflow Index](/reference/generated-workflows)

## Why Generated

This repo has a large surface area. Generated indexes reduce drift while letting the main docs stay opinionated and readable.
