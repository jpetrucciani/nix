# gofakes3

This directory packages [`gofakes3`](https://github.com/johannesboyne/gofakes3), a fake S3 server used for local development and test runs against S3-compatible APIs.

The package tracks the tagged v1.2.0 release, which includes the CORS fix that previously required a commit pin.

Upstream v1.2.0's Bolt backend returns object bytes that reference a closed read transaction. Later writes can invalidate those bytes, corrupting a GET response or causing a bus error. This package applies the Bolt read ownership patch from Opal, copying the bytes before BSON decoding so responses remain valid after the transaction closes. The package's test phase runs the upstream tests, including the patch's regression test against a real Bolt database.

---

## In this directory

### [default.nix](./default.nix)

This file defines the Go package build, including the release tag, source and vendored dependency hashes, and package metadata.

### [gofakes3-bolt-owned-reads.patch](./gofakes3-bolt-owned-reads.patch)

This patch fixes Bolt response ownership and adds a regression test that retains a GET response while later writes reuse database pages.
