# pog

This directory contains overlays that create tools with my [`pog`](https://github.com/jpetrucciani/pog) module!

Because this directory has many modules, this README highlights the most commonly useful ones instead of listing every file.

For the complete list, browse [`mods/pog`](./).

---

## Curated Highlights

### [hex](https://github.com/jpetrucciani/hex)

Hex is a nix module system that allows us to create powerful abstractions of other languages and configurations via nix! At the moment, this is the most useful for things like kubernetes specs!

### Cloud and Cluster Ops

- [aws.nix](./aws.nix): AWS-focused wrappers for common operations.
- [gcp.nix](./gcp.nix): GCP-focused wrappers for common operations.
- [k8s.nix](./k8s.nix): Kubernetes productivity wrappers.
- [k3s.nix](./k3s.nix): k3s-specific maintenance and operational helpers.
- [helm.nix](./helm.nix): Helm chart and repository analysis helpers.

### Local Development

- [db.nix](./db.nix): local database helpers for postgres, redis, and friends.
- [docker.nix](./docker.nix): docker wrappers for routine container workflows.
- [nix.nix](./nix.nix): helper commands for creating and managing nix environments.
- [ignore.nix](./ignore.nix): reusable gitignore line generators for common stacks.
- [general.nix](./general.nix): miscellaneous day-to-day helper commands.

### API and Automation

- [curl.nix](./curl.nix): ergonomic wrappers around curl usage patterns.
- [github.nix](./github.nix): CLI helpers for interacting with GitHub.
- [gitlab.nix](./gitlab.nix): CLI helpers for interacting with GitLab.
- [notion.nix](./notion.nix): wrappers for Notion API interactions.
- [discord.nix](./discord.nix): wrappers for Discord automation tasks.
- [loki.nix](./loki.nix): log query wrappers for Loki endpoints.
- [ssh.nix](./ssh.nix): wrappers around SSH operations.

### Media and Utility Modules

- [ffmpeg.nix](./ffmpeg.nix): media conversion shortcuts around ffmpeg.
- [sound.nix](./sound.nix): sound bite CLI wrappers.
- [ebook.nix](./ebook.nix): ebook tooling helpers.
- [resources/](./resources/): static assets used by selected pog modules.
