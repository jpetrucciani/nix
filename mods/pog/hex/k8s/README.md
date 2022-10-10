# k8s

hexes related to k8s specs and charts!

---

## In this directory

### [authentik.nix](./authentik.nix)

[Authentik](https://github.com/goauthentik/authentik) is an open source IDP written in go

### [cert-manager.nix](./cert-manager.nix)

[cert-manager](https://github.com/cert-manager/cert-manager/) adds certificates and certificate issuers as resource types in Kubernetes clusters, and simplifies the process of obtaining, renewing and using those certificates.

### [cron.nix](./cron.nix)

This hex spell allows very concise cron job declaration in Kubernetes.

### [external-secrets.nix](./external-secrets.nix)

[external-secrets](https://github.com/external-secrets/external-secrets) reads information from a third-party service like AWS Secrets Manager and automatically injects the values as Kubernetes Secrets.

### [gitlab-runner.nix](./gitlab-runner.nix)

This module contains the helm chart for the [GitLab Kubernetes Executor](https://docs.gitlab.com/runner/executors/kubernetes.html).

### [helm.nix](./helm.nix)

This module allows us to transparently use helm charts in hex spells!

### [nginx-ingress.nix](./nginx-ingress.nix)

[nginx-ingress controller](https://github.com/kubernetes/ingress-nginx)

### [services.nix](./services.nix)

This module allows us to create best-practices, all-inclusive k8s services with a set of powerful nix functions.

### [tailscale.nix](./tailscale.nix)

This module contains useful shorthands for using tailscale within kubernetes

### [traefik.nix](./traefik.nix)

[Traefik](https://github.com/traefik/traefik-helm-chart) is a modern HTTP reverse proxy and load balancer made to deploy microservices with ease.

### [woodpecker.nix](./woodpecker.nix)

[Woodpecker CI](https://github.com/woodpecker-ci/woodpecker) is a community fork of the Drone CI system
