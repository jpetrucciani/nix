{ hex, ... }:
{ name ? "litellm"
, namespace ? "default"
, image_registry ? "ghcr.io/berriai"
, image_base ? "litellm-database"
, image_tag ? "main-v1.44.26"
, image ? "${image_registry}/${image_base}:${image_tag}"
, replicas ? 1
, cpuRequest ? "0.5"
, cpuLimit ? "2"
, memoryRequest ? "1Gi"
, memoryLimit ? "4Gi"
, autoscale ? false
, extraEnv ? [ ]
, extraEnvAttrs ? { }
, port ? 4000
, secretName ? "litellm-secret"
, readinessProbe ? null
, maxUnavailable ? 0
, maxSurge ? "50%"
, litellm_config ? {
    model_list = [
      {
        litellm_params = {
          model = "groq/llama-3.1-70b-versatile";
          drop_params = true;
        };
        model_name = "llama-3.1-70b-versatile";
      }
    ];
  }
, litellm-conf ? "${name}-litellm-conf"
, labels ? {
    inherit name;
    tier = "api";
  }
, extraService ? { } # escape hatch to inject other service spec
}:
let
  inherit (hex) toYAMLDoc;

  config = {
    apiVersion = "v1";
    stringData = {
      "config.yaml" = hex.toYAML litellm_config;
    };
    kind = "Secret";
    metadata = {
      inherit namespace;
      labels = {
        HEX = "true";
      };
      name = litellm-conf;
    };
    type = "Opaque";
  };

  volumes = [
    {
      name = "litellm-conf";
      secret = litellm-conf;
      mountPath = "/etc/conf";
    }
    hex.k8s.services.components.volumes.tmp
  ];
  service = hex.k8s.services.build
    ({
      inherit name namespace labels port image replicas cpuRequest cpuLimit memoryRequest memoryLimit autoscale volumes readinessProbe maxUnavailable maxSurge;
      command = [ "litellm" ];
      args = [ "--config" "/etc/conf/config.yaml" ];
      envAttrs = {
        HEX = "true";
      } // extraEnvAttrs;
      envFrom = [
        { secretRef.name = secretName; }
      ];
      env = extraEnv;
      securityContext = { privileged = false; };
    } // extraService);
in
''
  ${toYAMLDoc config}
  ${service}
''
