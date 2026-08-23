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
- [e2b-cli.nix](./e2b-cli.nix): command line interface for e2b sandbox workflows.
- [gitlab-ci-verify.nix](./gitlab-ci-verify.nix): validate and lint GitLab CI files.

### Data and Visualization

- [arrow-tools.nix](./arrow-tools.nix): convert CSV/JSON into Arrow/Parquet data formats.
- [mermaid-rs-renderer.nix](./mermaid-rs-renderer.nix): fast native mermaid rendering.
- [terramaid.nix](./terramaid.nix): render terraform into mermaid diagrams.

### Ops and Diagnostics

- [comcast.nix](./comcast.nix): simulate degraded network conditions locally.
- [rare-go.nix](./rare-go.nix): realtime regex extraction and aggregation.
- [todo-reminder.nix](./todo-reminder.nix): scan code for TODO deadlines and formatting issues.
