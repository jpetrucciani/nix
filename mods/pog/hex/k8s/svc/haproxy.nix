{ hex, ... }:
{ name
, namespace ? "default"
, labels ? { inherit name; app = name; tier = "haproxy"; }
, image_base ? "haproxy"
, image_tag ? "3.0.3"
, image ? "${image_base}:${image_tag}"
, port ? 8443
, altPort ? null
, command ? [ "haproxy" "-f" "/etc/haproxy/haproxy.cfg" ]
, replicas ? 1
, cpuRequest ? "0.2"
, cpuLimit ? "1.0"
, memoryRequest ? "512Mi"
, memoryLimit ? "2048Mi"
, secret ? if haproxy-cfg != "" then "haproxy-cfg-${name}" else ""
, haproxy-cfg ? ""
, autoscale ? false
, extraEnv ? [ ]
, tailscale ? false
, hostAliases ? [ ]
, readinessProbe ? null
, maxUnavailable ? 0
, maxSurge ? "50%"
}:
let
  inherit (hex) toYAMLDoc;
  haproxy = hex.k8s.services.build {
    inherit name namespace port altPort command labels image replicas cpuRequest cpuLimit memoryRequest memoryLimit autoscale hostAliases readinessProbe maxUnavailable maxSurge;
    env = extraEnv;
    envFrom = [
      { secretRef.name = secret; }
    ];
    volumes = [
      {
        inherit secret;
        name = "haproxy-cfg";
        mountPath = "/etc/haproxy";
      }
    ];
    securityContext = { privileged = false; };
    tailscaleSidecar = tailscale;
  };
  config = {
    apiVersion = "v1";
    stringData = {
      "haproxy.cfg" = haproxy-cfg;
    };
    kind = "Secret";
    metadata = {
      inherit namespace;
      labels = {
        HEX = "true";
      };
      name = secret;
    };
    type = "Opaque";
  };
in
''
  ${if haproxy-cfg != "" then (toYAMLDoc config) else ""}
  ${haproxy}
''
