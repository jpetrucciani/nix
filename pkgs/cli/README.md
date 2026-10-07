# cli

This directory contains cli tools.

Because this directory has many entries, this README intentionally highlights representative tools instead of listing every package.

For the complete list, browse [`pkgs/cli`](./).

---

## Curated Highlights

### Developer Workflow

- [concurrently.nix](./concurrently.nix): run multiple commands in parallel.
- [t-rs.nix](./t-rs.nix): concise text transformation language.

### Cloud and Infrastructure

- [aws-secretsmanager-agent.nix](./aws-secretsmanager-agent.nix): local cached access to AWS Secrets Manager.
- [helm-oci.nix](./helm-oci.nix): list and inspect helm charts in OCI registries.
- [terraform_1-5-5/](./terraform_1-5-5/): patched Terraform 1.5.5 build for legacy workflows.
- [e2b-cli/](./e2b-cli/): command line interface for E2B sandbox workflows, using a versioned npm lock hosted on
  `static.g7c.us`. Run `nix run .#e2b-cli.updateScript` to generate and publish the next lock, update the package,
  build it, and verify the CLI.
- [gitlab-ci-verify.nix](./gitlab-ci-verify.nix): validate and lint GitLab CI files.

### Data and Visualization

- [arrow-tools.nix](./arrow-tools.nix): convert CSV/JSON into Arrow/Parquet data formats.
- [fframes.nix](./fframes.nix): create Rust and SVG video projects with `cargo-fframes`.
- [mermaid-rs-renderer.nix](./mermaid-rs-renderer.nix): fast native mermaid rendering.
- [terramaid.nix](./terramaid.nix): render terraform into mermaid diagrams.

### Ops and Diagnostics

- [comcast.nix](./comcast.nix): simulate degraded network conditions locally.
- [rare-go.nix](./rare-go.nix): realtime regex extraction and aggregation.
- [todo-reminder.nix](./todo-reminder.nix): scan code for TODO deadlines and formatting issues.

## fframes

[fframes.nix](./fframes.nix) packages the `cargo-fframes` project generator. Run these commands from the repository root:

```bash
nix build .#fframes
nix run .#fframes -- new my-video --yes --backend cpu
```

With the package and Cargo on `PATH`, the equivalent command is `cargo fframes new my-video --yes --backend cpu`.
The generated project contains the renderer; building it requires a Rust toolchain and the native libraries listed in
[upstream's requirements](https://github.com/dmtrKovalenko/fframes/tree/v1.2.0#requirements).
The CPU backend skips Skia but still needs FFmpeg and the selected codec libraries.

Once the native build environment is ready:

```bash
cd my-video
cargo run --release -- inspect
cargo run --release -- render --draft
```

The [upstream examples](https://github.com/dmtrKovalenko/fframes/tree/v1.2.0#examples) include `hello-world`,
`motion-graphics`, `signal-lab`, and GPU shader demos. The `motion-graphics` package also has a `quote` binary that uses
its bundled fonts; its main demo references `Helvetica Neue`, which is not bundled.

The Linux example test found that upstream's prebuilt FFmpeg expects x264 ABI 163, while the current Nix package provides
ABI 165. If linking fails with `x264_encoder_open_163`, use `FFMPEG_FORCE_BUILD=1` to compile FFmpeg against the codec
libraries in the prepared native build environment, or provide the matching x264 ABI. The quote-card render was tested
with a matching ABI 163 library in a temporary environment; this package does not provide that rendering environment.
