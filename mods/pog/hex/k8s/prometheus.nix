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
      version = "56.1.0";
      sha256 = "18vhd3455pq894gnanczkns6mw18byk9hhvyn8iz1ss17wyqcaif";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v56-1-0;
      v56-1-0 = _v "56.1.0" "18vhd3455pq894gnanczkns6mw18byk9hhvyn8iz1ss17wyqcaif";
      v55-11-0 = _v "55.11.0" "06l4bn25illfwm2k0jlibxz2ndqbl09xg7mim2ym0rim0m0rljfl";
      v54-2-2 = _v "54.2.2" "051mdacf2z442qqmj4gp62h8xx0wjm4k5jh8sxnd8ar5nr24jyhs";
      v53-0-0 = _v "53.0.0" "0gl5bd5dbwhxg0zi1mygdgg0j080vk346dipi4sc8gq0b583vy8s";
      v52-1-0 = _v "52.1.0" "0ahd8cw7kx7hgnffw6jiyhdvpg5iwn2k8qq1y01dfk7rbbcxnpsr";
      v51-10-0 = _v "51.10.0" "1yw9bkgiws4d34fbavnlhk87srfvvpv1dajyk8v7npai237415dq";
      v50-3-1 = _v "50.3.1" "12dy66syz0417z75kwmzciv4s4g93fd03n5jrzzyridzbr3mdiv7";
      v49-2-0 = _v "49.2.0" "0wvwlfp07827z1zxxnaizvcgrla9paz4f127dfgx86jlc07s9xci";
      v48-6-0 = _v "48.6.0" "0xsfvnl9vfh7skjlim0xgw6dxfp393lr0001sv1icmpfq8fkvlrr";
      v48-4-0 = _v "48.4.0" "0wvl3n2ds3jgfb0cbwp1dq59xh7zyqh7mvhw6ndiyzsyssipg573";
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
