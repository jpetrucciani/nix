# pog

This directory contains overlays that create tools with my [`pog`](../pog.nix) module!

---

## In this directory

### [hex/](./hex/)

Hex is a nix module system that allows us to create powerful abstractions of other languages and configurations via nix! At the moment, this is the most useful for things like kubernetes specs!

### [aws.nix](./aws.nix)

This module makes some AWS related tools with `pog`.

### [curl.nix](./curl.nix)

this file provides some pog wrappers around curl to make it a bit more ergonomic

### [db.nix](./db.nix)

this set of pog scripts allows us to use postgres, redis, etc. in local dev environments via nix

### [docker.nix](./docker.nix)

This module creates some `pog` tools that help make you more productive in Docker!

### [ffmpeg.nix](./ffmpeg.nix)

This module provides some shorthand `pog` helpers that simplify some ffmpeg workflows!

### [gcp.nix](./gcp.nix)

This module makes some GCP related tools with `pog`.

### [general.nix](./general.nix)

This module provides miscellaneous `pog` implemented tools

### [github.nix](./github.nix)

This module provides some tools that interact with GitHub

### [hax.nix](./hax.nix)

This module provides some hacky `pog` tools!

### [helm.nix](./helm.nix)

This module provides some tools for analyzing helm repos and charts!

### [ignore.nix](./ignore.nix)

this module sets up a list of gitignore lines for various languages

### [k3s.nix](./k3s.nix)

This module creates some `pog` tools specific to [k3s](https://github.com/k3s-io/k3s) cluster maintenance!

### [k8s.nix](./k8s.nix)

This module creates some `pog` tools that help make you more productive in [Kubernetes](https://kubernetes.io/)!

### [nix.nix](./nix.nix)

This module configures some helper tools for creating new nix environments!

### [notion.nix](./notion.nix)

this pog module includes tools to interact with notion

### [sound.nix](./sound.nix)

This module contains a `soundScript` wrapper that uses `pog` to create command line sound bites!

### [ssh.nix](./ssh.nix)

this set of pog scripts creates some wrappers around ssh to make things easier
