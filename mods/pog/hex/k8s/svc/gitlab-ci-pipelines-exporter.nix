{ hex, pkgs, ... }:
{ name ? "gitlab-ci-pipelines-exporter"
, namespace ? "default"
, image_registry ? "ghcr.io"
, image_base ? "mvisonneau/gitlab-ci-pipelines-exporter"
, image_tag ? "v0.5.8" # or latest?
, image ? "${image_registry}/${image_base}:${image_tag}"
, replicas ? 1
, cpuRequest ? "0.2"
, cpuLimit ? "1"
, memoryRequest ? "1Gi"
, memoryLimit ? "4Gi"
, autoscale ? false
, extraEnv ? [ ]
, port ? 8080
, labels ? {
    inherit name;
    upstream = "gitlab-ci";
    tier = "exporter";
  }
, extraService ? { } # escape hatch to inject other service spec
, secret ? ""
, gcpe-cfg ? ""
, configSecret ? if gcpe-cfg != "" then "gcpe-cfg-${name}" else ""
}:
let
  inherit (hex) toYAMLDoc;
  inherit (pkgs.lib) recursiveUpdate;
  config = {
    apiVersion = "v1";
    stringData = {
      "config.yml" = gcpe-cfg;
    };
    kind = "Secret";
    metadata = {
      inherit namespace;
      labels = {
        HEX = "true";
      };
      name = configSecret;
    };
    type = "Opaque";
  };
  volumes = [
    hex.k8s.services.components.volumes.tmp
    {
      secret = configSecret;
      name = "gcpe-cfg";
      mountPath = "/etc/gcpe";
    }
  ];
  gcpe = hex.k8s.services.build (recursiveUpdate
    {
      inherit name namespace labels port image replicas cpuRequest cpuLimit memoryRequest memoryLimit autoscale volumes;
      envAttrs = {
        PORT = toString port;
        HEX = "true";
        GCPE_CONFIG = "/etc/gcpe/config.yml";
      };
      env = extraEnv;
      ${if secret != "" then "envFrom" else null} = [{ secretRef.name = secret; }];
      securityContext = { privileged = false; };
    }
    extraService);
in
''
  ${if gcpe-cfg != "" then (toYAMLDoc config) else ""}
  ${gcpe}
''
