{ hex, pkgs, ... }:
{ name ? "langfuse"
, namespace ? "default"
, image_base ? "langfuse/langfuse"
, image_tag ? "sha-f3596fa"
, image ? "${image_base}:${image_tag}"
, replicas ? 1
, cpuRequest ? "0.2"
, cpuLimit ? "1"
, memoryRequest ? "1Gi"
, memoryLimit ? "4Gi"
, autoscale ? false
, extraEnv ? [ ]
, extraEnvAttrs ? { }
, port ? 10000
, secretName ? "langfuse-secret"
, readinessProbe ? null
, maxUnavailable ? 0
, maxSurge ? "50%"
, labels ? {
    inherit name;
    tier = "infra";
  }
, extraService ? { } # escape hatch to inject other service spec
  # langfuse specific
, telemetryEnabled ? false
, experimentalFeatures ? true
}:
let
  inherit (pkgs.lib) recursiveUpdate;
  volumes = [ hex.k8s.services.components.volumes.tmp ];
in
hex.k8s.services.build (recursiveUpdate
{
  inherit name namespace labels port image replicas cpuRequest cpuLimit memoryRequest memoryLimit autoscale volumes readinessProbe maxUnavailable maxSurge;
  envAttrs = {
    LANGFUSE_ENABLE_EXPERIMENTAL_FEATURES = toString experimentalFeatures;
    TELEMETRY_ENABLED = toString telemetryEnabled;
    PORT = toString port;
    HEX = "true";
  } // extraEnvAttrs;
  envFrom = [{ secretRef.name = secretName; }];
  env = extraEnv;
  securityContext = { privileged = false; };
}
  extraService)
