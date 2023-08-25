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
  kube-prometheus-stack = rec {
    defaults = {
      name = "prometheus";
      namespace = "default";
      version = "48.4.0";
      sha256 = "0wvl3n2ds3jgfb0cbwp1dq59xh7zyqh7mvhw6ndiyzsyssipg573";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v48-4-0;
      v48-4-0 = _v defaults.version defaults.sha256;
    };
    chart_url = version:
      let name = "kube-prometheus-stack"; in
      "https://github.com/prometheus-community/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
    chart =
      { name ? defaults.name
      , namespace ? defaults.namespace
      , values ? [ ]
      , sets ? [ ]
      , version ? defaults.version
      , sha256 ? defaults.sha256
      , forceNamespace ? false
      , extraFlags ? [
          "--version=${version}"
        ]
      , sortYaml ? false
      }: hex.k8s.helm.build {
        inherit name namespace values sets version sha256 extraFlags forceNamespace sortYaml;
        url = chart_url version;
      };
  };
}
