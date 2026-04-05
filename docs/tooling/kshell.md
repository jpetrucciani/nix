# kshell

[`kshell`](https://github.com/jpetrucciani/nix/blob/main/mods/pog/k8s.nix) is the repo's quick way to launch an ephemeral interactive pod with just enough pod-spec control to be useful in real clusters.

It exists for the cases where plain `kubectl run ... -- sh` is too bare, but writing out a full manifest is overkill.

## What It Can Shape

- image and namespace selection
- service account selection
- extra pod labels
- container `env` values
- `envFrom` secret refs
- image pull secrets
- node selectors
- resource requests and limits
- tolerations
- secret and ConfigMap volume mounts

`kshell` also adds a couple of default labels:

- `app.kubernetes.io/name=kshell`
- `app.kubernetes.io/managed-by=pog`

## Input Formats

Most flags use short comma-separated forms:

- `--labels app=debug,owner=jacobi`
- `--env LOG_LEVEL=debug,FEATURE_FLAG=1`
- `--envfromsecret app-env,shared-env`
- `--imagepullsecrets regcred,mirror-cred`
- `--nodeselector kubernetes.io/arch=amd64,topology.kubernetes.io/zone=us-east-1a`
- `--requests cpu=250m,memory=256Mi`
- `--limits cpu=1,memory=1Gi`
- `--volumesecrets app-creds=/var/run/secrets/app`
- `--volumeconfigmaps app-config=/etc/app`

`--tolerations` is the odd one out because each toleration is an object:

```bash
--tolerations 'key=spot,operator=Exists,effect=NoSchedule;key=dedicated,operator=Equal,value=debug,effect=NoSchedule'
```

That is a quoted semicolon-separated list, where each toleration is itself a comma-separated `key=value` list.

## Examples

### Private Image on a Specific Node Pool

```bash
kshell \
  --namespace payments \
  --serviceaccount payments-api \
  --image ghcr.io/acme/debug:latest \
  --imagepullsecrets regcred \
  --nodeselector kubernetes.io/arch=amd64,nodepool=apps \
  --labels app=payments-debug,owner=jacobi
```

### Resource-Bounded Debug Shell With Environment

```bash
kshell \
  --namespace data \
  --image cgr.dev/chainguard/wolfi-base \
  --env LOG_LEVEL=debug,FEATURE_FLAG=1 \
  --envfromsecret warehouse-env \
  --requests cpu=250m,memory=256Mi \
  --limits cpu=1,memory=1Gi
```

### Run on Tainted Nodes

```bash
kshell \
  --namespace infra \
  --image alpine:3.20 \
  --nodeselector nodepool=ops \
  --tolerations 'key=dedicated,operator=Equal,value=ops,effect=NoSchedule;key=spot,operator=Exists,effect=NoSchedule'
```

### Mount a Secret and a ConfigMap

```bash
kshell \
  --namespace api \
  --image busybox:1.36 \
  --volumesecrets api-creds=/var/run/secrets/api \
  --volumeconfigmaps api-config=/etc/api \
  --env CONFIG_DIR=/etc/api
```

### Full-Fat Example

```bash
kshell \
  --namespace search \
  --serviceaccount search-api \
  --image ghcr.io/acme/search-debug:latest \
  --labels app=search-debug,owner=jacobi,incident=inc-4821 \
  --env LOG_LEVEL=trace,OTEL_SERVICE_NAME=search-debug \
  --envfromsecret search-env,shared-observability \
  --imagepullsecrets regcred \
  --nodeselector kubernetes.io/arch=amd64,nodepool=apps \
  --requests cpu=500m,memory=512Mi \
  --limits cpu=2,memory=2Gi \
  --tolerations 'key=dedicated,operator=Equal,value=search,effect=NoSchedule' \
  --volumesecrets search-creds=/var/run/secrets/search \
  --volumeconfigmaps search-config=/etc/search
```

## Notes

- `--env`, `--labels`, selectors, and resource flags all expect comma-separated `key=value` pairs.
- `--volumesecrets` and `--volumeconfigmaps` expect `source=/mount/path`.
- Values are merged into `kubectl run --override-type=strategic --overrides`, so container-level fields augment the generated pod instead of replacing it wholesale.
- If you need more than one mount of the same secret or ConfigMap at different paths, the current helper is still a bit opinionated. At that point, YAML may be less offensive than more flag syntax.

## Read Next

- [pog](/tooling/pog)
- [Tooling Overview](/tooling/index)
