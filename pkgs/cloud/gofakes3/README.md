# gofakes3

This directory packages [`gofakes3`](https://github.com/johannesboyne/gofakes3), a fake S3 server used for local development and test runs against S3-compatible APIs.

The package is pinned to a specific upstream commit because this repo relies on an unreleased patch that is not part of the last tagged release yet.

---

## In this directory

### [default.nix](./default.nix)

This file defines the Go package build, including the pinned upstream commit, vendored dependency hash, and package metadata.
