{ hex, ... }:
let
  inherit (hex) ifNotEmptyList toYAML;
in
{
  gmp = {
    pod_monitoring = { name, port, matchLabels, namespace ? "default", interval ? "30s", metricRelabeling ? [ ] }: (toYAML {
      apiVersion = "monitoring.googleapis.com/v1";
      kind = "PodMonitoring";
      metadata = {
        inherit name namespace;
      };
      spec = {
        endpoints = [
          {
            inherit interval port;
            ${ifNotEmptyList metricRelabeling "metricRelabeling"} = metricRelabeling;
          }
        ];
        selector = {
          inherit matchLabels;
        };
      };
    });
  };
}
