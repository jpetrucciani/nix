{ hex, pkgs, ... }:
{ name ? "lobe-chat"
, namespace ? "default"
, image_base ? "lobehub/lobe-chat"
, image_tag ? "v1.21.8"
, image ? "${image_base}:${image_tag}"
, replicas ? 1
, cpuRequest ? "0.2"
, cpuLimit ? "1"
, memoryRequest ? "1Gi"
, memoryLimit ? "4Gi"
, autoscale ? false
, extraEnv ? [ ]
, extraEnvAttrs ? { }
, port ? 3210
, secretName ? "lobe-chat-secret"
, readinessProbe ? null
, maxUnavailable ? 0
, maxSurge ? "50%"
, labels ? {
    inherit name;
    tier = "app";
  }
, extraService ? { } # escape hatch to inject other service spec
}:
let
  inherit (pkgs.lib) recursiveUpdate;
  volumes = [ hex.k8s.services.components.volumes.tmp ];
in
hex.k8s.services.build (recursiveUpdate
{
  inherit name namespace labels port image replicas cpuRequest cpuLimit memoryRequest memoryLimit autoscale volumes readinessProbe maxUnavailable maxSurge;
  envAttrs = {
    PORT = toString port;
    HEX = "true";
  } // extraEnvAttrs;
  envFrom = [{ secretRef.name = secretName; }];
  env = extraEnv;
  securityContext = { privileged = false; };
}
  extraService)
