# k8s

hexes related to k8s specs and charts!

---

## In this directory

### [svc/](./svc/)

individual service hexes

### [addons.nix](./addons.nix)

various cluster addons [out of date]

### [airbyte.nix](./airbyte.nix)

a hex module for [airbyte](https://github.com/airbytehq/airbyte), an ETL pipeline tool

### [argocd.nix](./argocd.nix)

[argocd](https://github.com/argoproj/argo-cd) is declarative continuous deployment for kubernetes

### [authentik.nix](./authentik.nix)

[Authentik](https://github.com/goauthentik/authentik) is an open source IDP written in go

### [aws.nix](./aws.nix)

This module contains k8s helpers for AWS related functionality

### [cert-manager.nix](./cert-manager.nix)

[cert-manager](https://github.com/cert-manager/cert-manager/) adds certificates and certificate issuers as resource types in Kubernetes clusters, and simplifies the process of obtaining, renewing and using those certificates.

### [cron.nix](./cron.nix)

This hex spell allows concise cron job declaration in Kubernetes.

### [datadog.nix](./datadog.nix)

[datadog](https://github.com/DataDog/helm-charts) provides helm charts to add logging and monitoring to your clusters. WARNING - extremely expensive!

### [elastic.nix](./elastic.nix)

This module contains an [elastic operator](https://github.com/elastic/cloud-on-k8s/)

### [external-secrets.nix](./external-secrets.nix)

[external-secrets](https://github.com/external-secrets/external-secrets) reads information from a third-party service like AWS Secrets Manager and automatically injects the values as Kubernetes Secrets.

### [fission.nix](./fission.nix)

[fission](https://github.com/fission/fission) is a serverless function platform for k8s

### [flipt.nix](./flipt.nix)

[flipt](https://github.com/flipt-io/flipt) is a feature flag service built with Go

### [gitlab-runner.nix](./gitlab-runner.nix)

This module contains the helm chart for the [GitLab Kubernetes Executor](https://docs.gitlab.com/runner/executors/kubernetes.html).

### [grafana.nix](./grafana.nix)

This module contains helm charts under the [grafana](https://grafana.com/) observability umbrella. This includes things like [loki](https://github.com/grafana/loki), [mimir](https://github.com/grafana/mimir), and [oncall](https://github.com/grafana/oncall).

### [helm.nix](./helm.nix)

This module allows us to transparently use [helm](https://github.com/helm/helm) charts in hex spells!

### [infisical.nix](./infisical.nix)

This module contains an [infisical](https://github.com/Infisical/infisical) helm chart

### [jupyterhub.nix](./jupyterhub.nix)

[jupyterhub](https://github.com/jupyterhub/jupyterhub) is a platform for hosting Jupyter notebooks for many users

### [langflow.nix](./langflow.nix)

[langflow](https://github.com/langflow-ai/langflow) is a visual framework for building multi-agent and RAG applications

### [mongo.nix](./mongo.nix)

[mongodb-operator](https://github.com/mongodb/mongodb-kubernetes-operator) is a way to deploy and maintain mongodb deployments on k8s

### [nginx-ingress.nix](./nginx-ingress.nix)

[nginx-ingress controller](https://github.com/kubernetes/ingress-nginx)

### [oneuptime.nix](./oneuptime.nix)

[oneuptime](https://github.com/OneUptime/oneuptime) is a self-hostable observability platform

### [otf.nix](./otf.nix)

[otf](https://github.com/jpetrucciani/otf) is an open source terraform cloud alternative

### [postgres.nix](./postgres.nix)

[postgres-operator](https://github.com/zalando/postgres-operator) creates and manages PostgreSQL clusters running in Kubernetes

### [prometheus.nix](./prometheus.nix)

Helpers for [prometheus](https://github.com/prometheus/prometheus) related things in k8s land!

### [quickwit.nix](./quickwit.nix)

[quickwit](https://github.com/quickwit-oss/quickwit) is a Cloud-native search engine for observability. An open-source alternative to Datadog, Elasticsearch, Loki, and Tempo

### [rancher.nix](./rancher.nix)

[rancher](https://github.com/rancher/rancher) is an open-source multi-cluster orchestration platform

### [redis.nix](./redis.nix)

[redis-operator](https://github.com/spotahome/redis-operator) creates/configures/manages high availability redis with sentinel automatic failover atop Kubernetes

### [robusta.nix](./robusta.nix)

[robusta](https://github.com/robusta-dev/robusta) is a Kubernetes observability and automation, with an awesome Prometheus integration

### [sentry.nix](./sentry.nix)

[sentry](https://github.com/getsentry/sentry) is a Developer-first error tracking and performance monitoring platform.

### [services.nix](./services.nix)

This module allows us to create best-practices, all-inclusive k8s services with a set of powerful nix functions.

### [signoz.nix](./signoz.nix)

This module contains the [signoz](https://github.com/SigNoz/signoz) helm chart

### [stackstorm.nix](./stackstorm.nix)

K8s Helm module for running a [StackStorm](https://stackstorm.com) cluster in HA mode.

### [storage.nix](./storage.nix)

helpers for defining PVs and PVCs

### [tailscale.nix](./tailscale.nix)

This module contains useful shorthands for using [tailscale](https://tailscale.com/) within kubernetes

### [tofutf.nix](./tofutf.nix)

[tofutf](https://github.com/tofutf/tofutf) is an open source terraform cloud alternative

### [traefik.nix](./traefik.nix)

[Traefik](https://github.com/traefik/traefik-helm-chart) is a modern HTTP reverse proxy and load balancer made to deploy microservices with ease.
