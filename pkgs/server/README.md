# server

This directory contains specific servers

---

## In this directory

### [argus-rs.nix](./argus-rs.nix)

[argus](https://github.com/jpetrucciani/argus) is a customizable http request logger with prometheus metrics

### [epimetheus.nix](./epimetheus.nix)

[epimetheus](https://github.com/jpetrucciani/epimetheus) is a swiss army knife prometheus exporter capable of watching json/csv/yaml files and providing prometheus metrics

### [hasura-batteries.nix](./hasura-batteries.nix)

[hasura-batteries](https://github.com/RocketsGraphQL/hasura-batteries) is a service that runs alongside Hasura GraphQL engine giving it superpowers like Authentication

### [obligator.nix](./obligator.nix)

[obligator](https://github.com/lastlogin-net/obligator) is an OIDC server designed for self-hosters

### [obscura.nix](./obscura.nix)

[obscura](https://github.com/h4ckf0r0day/obscura) is the headless browser for AI agents and web scraping

Run `nix run .#obscura.updateScript` to refresh the pinned Linux and macOS release archives.

### [obscura.json](./obscura.json)

Pinned release version and platform archive metadata consumed by the package.

### [picomq.nix](./picomq.nix)

[PicoMQ](https://github.com/picomq/picomq) provides durable real-time streams over HTTP backed by S3-compatible object storage

### [poglets.nix](./poglets.nix)

[poglets](https://github.com/jpetrucciani/poglets) is a TCP tunneling system

### [pogocache.nix](./pogocache.nix)

[pogocache](https://github.com/tidwall/pogocache) is fast caching software focused on low latency and CPU efficiency

Run `nix run .#pogocache.updateScript` to refresh the pinned static Linux and macOS release archives.

### [pogocache.json](./pogocache.json)

Pinned release version and platform archive metadata consumed by the package.

### [rdpgw.nix](./rdpgw.nix)

[rdpgw](https://github.com/bolkedebruin/rdpgw) is a Remote Desktop Gateway in Go for deploying on Linux/BSD/Kubernetes

Run `nix run .#rdpgw.updateScript` to follow the fork's `add_go_sum` branch, refresh both hashes, and validate the
candidate build before replacing the package expression.

### [rdpgw-help.patch](./rdpgw-help.patch)

Makes RDpgw treat an already-rendered help request as a successful exit instead of panicking.

### [semaphore.nix](./semaphore.nix)

[semaphore](https://github.com/semaphoreui/semaphore) is a web UI for Ansible, Terraform/OpenTofu, PowerShell, and shell tasks

### [smoothmq.nix](./smoothmq.nix)

[smoothmq](https://github.com/poundifdef/SmoothMQ) is A drop-in replacement for SQS designed for great developer experience and efficiency

### [titanite.nix](./titanite.nix)

titanite is a policy-aware DNS service for homelabs and small production networks
