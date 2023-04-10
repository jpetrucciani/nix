# pkgs

This directory contains nix packages that I've built that are not yet ready for nixpkgs proper, or that don't make sense to open as a PR to nixpkgs proper. These are broken out into individual overlays for organization

---

## In this directory

### [caddy.nix](./caddy.nix)

This overlay provides a [caddy web server](https://caddyserver.com/v2) builder function called `_zaddy` and a set of default plugins that you can use to build any flavor of caddy that you'd like!

### [cli.nix](./cli.nix)

This overlay provides general CLI tools for use in text transformation and other use cases.

##### rare

[![built in go](https://img.shields.io/badge/built%20in-go-%2301ADD8)](https://go.dev/)

This package provides [rare](https://github.com/zix99/rare) in nixpkgs, a tool that allows regex-extraction and aggregation into common formats such as histograms, bar graphs, numerical summaries, tables, and more.

### [cloud.nix](./cloud.nix)

##### aliyun-cli

[![built in go](https://img.shields.io/badge/built%20in-go-%2301ADD8)](https://go.dev/)

This package provides the [Alibaba Cloud CLI](https://github.com/aliyun/aliyun-cli) in nixpkgs, a CLI tool for the Alibaba Cloud platform. Written in Go.

### [k8s.nix](./k8s.nix)

This overlay provides a handful of kubernetes related tools, like below:

##### goldilocks

[![built in go](https://img.shields.io/badge/built%20in-go-%2301ADD8)](https://go.dev/)

[Goldilocks](https://github.com/FairwindsOps/goldilocks) is a utility that can help you identify a starting point for resource requests and limits.

##### katafygio

[![built in go](https://img.shields.io/badge/built%20in-go-%2301ADD8)](https://go.dev/)

##### kube-linter

[![built in go](https://img.shields.io/badge/built%20in-go-%2301ADD8)](https://go.dev/)

This package provides [kube-linter](https://github.com/stackrox/kube-linter) in nixpkgs, a static analysis tool that checks Kubernetes YAML files and Helm charts to ensure the applications represented in them adhere to best practices

##### pluto

[![built in go](https://img.shields.io/badge/built%20in-go-%2301ADD8)](https://go.dev/)

This package provides [pluto](https://github.com/FairwindsOps/Pluto) in nixpkgs, a cli tool to help discover deprecated apiVersions in Kubernetes.

##### polaris

[![built in go](https://img.shields.io/badge/built%20in-go-%2301ADD8)](https://go.dev/)

[Polaris](https://github.com/FairwindsOps/polaris/) keeps your clusters sailing. It runs a variety of checks to ensure that Kubernetes pods and controllers are configured using best practices, helping you avoid problems in the future.

##### rbac-tool

[![built in go](https://img.shields.io/badge/built%20in-go-%2301ADD8)](https://go.dev/)

This package provides [rbac-tool](https://github.com/alcideio/rbac-tool) in nixpkgs, a tool that simplifies querying and creation of RBAC policies.

### [server.nix](./server.nix)

This overlay provides some servers/services that are built as nix derivations, such as specific versions of [haproxy](http://www.haproxy.org/), and stuff like [pocketbase](https://github.com/pocketbase/pocketbase/).
