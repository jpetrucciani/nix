{ hex, ... }:
{ name ? "whoogle"
, namespace ? "default"
, image ? "${image_base}:${image_tag}"
, image_base ? "benbusby/whoogle-search"
, image_tag ? "0.8.1"
, replicas ? 1
, cpuRequest ? "0.1"
, cpuLimit ? "0.2"
, memoryRequest ? "128Mi"
, memoryLimit ? "256Mi"
, autoscale ? false
, port ? 5000
, extraEnv ? [ ]
}:
let
  labels = {
    inherit name;
    tier = "api";
  };
  probe = {
    httpGet = {
      inherit port;
      path = "/healthz";
    };
    failureThreshold = 2;
    initialDelaySeconds = 10;
    periodSeconds = 10;
    successThreshold = 1;
    timeoutSeconds = 4;
  };
in
hex.k8s.services.build {
  inherit name namespace labels port image replicas cpuRequest cpuLimit memoryRequest memoryLimit autoscale;
  softAntiAffinity = true;
  env = [
    {
      name = "WHOOGLE_CONFIG_THEME";
      value = "dark";
    }
  ] ++ extraEnv;
  livenessProbe = probe;
  readinessProbe = probe;
  securityContext = { privileged = false; };
}
