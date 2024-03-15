# an example of how to use included helm charts in hex! you can find the [list of hex modules here](../../mods/pog/hex/k8s)
{ hex }:
hex.flat [
  # deploy a version of external-secrets
  (hex.k8s.external-secrets.version.v0-9-13 { })

  # deploy traefik with some options tweaked
  (hex.k8s.traefik.version.v26-1-0 {
    exposeHttps = false;
    replicas = 2;
    portHttp = 8088;
  })
]
