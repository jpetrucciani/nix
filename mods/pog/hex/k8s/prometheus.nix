{ hex, ... }:
let
  inherit (hex) ifNotEmptyList ifNotNull toYAML;
in
{
  gmp = {
    pod_monitoring =
      { name
      , port
      , matchLabels
      , path ? "/metrics"
      , timeout ? null
      , namespace ? "default"
      , interval ? "30s"
      , metricRelabeling ? [ ]
      }:
      let
        monitor = {
          apiVersion = "monitoring.googleapis.com/v1";
          kind = "PodMonitoring";
          metadata = {
            inherit name namespace;
          };
          spec = {
            endpoints = [
              {
                inherit interval port path;
                ${ifNotEmptyList metricRelabeling "metricRelabeling"} = metricRelabeling;
                ${ifNotNull timeout "timeout"} = timeout;
              }
            ];
            selector = {
              inherit matchLabels;
            };
          };
        };
      in
      ''
        ---
        ${toYAML monitor}
      '';
  };
}
