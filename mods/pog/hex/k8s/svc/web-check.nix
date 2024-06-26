{ hex, ... }:
{ name ? "web-check"
, namespace ? "default"
, image_registry ? "lissy93"
, image_base ? "web-check"
, image_tag ? "latest"
, image ? "${image_registry}/${image_base}:${image_tag}"
, replicas ? 1
, cpuRequest ? "0.2"
, cpuLimit ? "1"
, memoryRequest ? "1Gi"
, memoryLimit ? "4Gi"
, autoscale ? false
, extraEnv ? [ ]
, port ? 3000
, disableGui ? false
, labels ? {
    inherit name;
    tier = "api";
  }
, extraService ? { } # escape hatch to inject other service spec
}:
let
  inherit (hex) boolToString;
  volumes = [ hex.k8s.services.components.volumes.tmp ];
in
hex.k8s.services.build ({
  inherit name namespace labels port image replicas cpuRequest cpuLimit memoryRequest memoryLimit autoscale volumes;
  envAttrs = {
    DISABLE_GUI = boolToString disableGui;
    PORT = toString port;
    HEX = "true";
  };
  env = extraEnv;
  securityContext = { privileged = false; };
} // extraService)
