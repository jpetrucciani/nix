# cloud

This directory contains tooling related to various cloud providers

---

## In this directory

### [coscli.nix](./coscli.nix)

[coscli](https://github.com/tencentyun/coscli) is a tencent cloud command line tool

### [fake-gcs-server.nix](./fake-gcs-server.nix)

[fake-gcs-server](https://github.com/fsouza/fake-gcs-server) is a google cloud storage emulator

### [gcsproxy.nix](./gcsproxy.nix)

[gcsproxy](https://github.com/daichirata/gcsproxy/) is a reverse proxy for google cloud storage

### [gke-gcloud-auth-plugin.nix](./gke-gcloud-auth-plugin.nix)

gke-gcloud-auth-plugin is a required plugin for using kubectl with Google's GKE on GCP

Run `nix run .#gke-gcloud-auth-plugin.updateScript` to update it from the component manifest matching the pinned
Google Cloud SDK, or pass a specific SDK version after `--`.

### [gke-gcloud-auth-plugin.json](./gke-gcloud-auth-plugin.json)

Pinned plugin version, component-manifest revision, and platform archive metadata consumed by the package.

### [goaws.nix](./goaws.nix)

[goaws](https://github.com/Admiral-Piett/goaws) is a SQS/SNS Clone for Development testing

### [gofakes3/](./gofakes3/)

[gofakes3](https://github.com/johannesboyne/gofakes3) is a fake s3 server

### [headscale-ui.nix](./headscale-ui.nix)

[headscale-ui](https://github.com/gurucomputing/headscale-ui) is a web frontend for headscale management

Run `nix run .#headscale-ui.updateScript` to refresh the pinned static-site release.

### [headscale-ui.json](./headscale-ui.json)

Pinned release version and archive metadata consumed by the package.

### [otfd.nix](./otfd.nix)

[otfd](https://github.com/jpetrucciani/otf) is an open source terraform cloud

### [s3-edit.nix](./s3-edit.nix)

[s3-edit](https://github.com/tsub/s3-edit) is a cli tool for editing s3 files directly

### [stree.nix](./stree.nix)

[stree](https://github.com/orangekame3/stree) is a directory tree tool for s3

Run `nix run .#nupdate -- stree` to update the source and Go dependency hashes.

### [stree-version.patch](./stree-version.patch)

Removes the misleading runtime-generated build timestamp from `stree --version`.
