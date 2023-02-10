{ hex, ... }:
let
  inherit (hex) ifNotEmptyList toYAML;
in
{
  gmp = {
    pod_monitoring = { name, port, matchLabels, interval ? "30s", metricRelabeling ? [ ] }: (toYAML {
      apiVersion = "monitoring.googleapis.com/v1";
      kind = "PodMonitoring";
      metadata = {
        inherit name;
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
