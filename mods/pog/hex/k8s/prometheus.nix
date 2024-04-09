# Helpers for [prometheus](https://github.com/prometheus/prometheus) related things in k8s land!
{ hex, ... }:
let
  inherit (hex) ifNotEmptyList ifNotNull toYAMLDoc;
  prom_chart = name: version: "https://github.com/prometheus-community/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
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
      toYAMLDoc monitor;
  };
  kube-prometheus-stack = rec {
    defaults = {
      name = "prometheus";
      namespace = "default";
      version = "58.0.0";
      sha256 = "0kr65dkhk8728sdg1lm562zqsknpnw6wfq3jdg150d8yzlz3cdrg";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v58-0-0;
      v58-0-0 = _v "58.0.0" "0kr65dkhk8728sdg1lm562zqsknpnw6wfq3jdg150d8yzlz3cdrg"; # 2024-04-06
      v57-2-1 = _v "57.2.1" "1p87qngiab98n6l59432harkmg53c9vk1wl7hmfllp7wphcflsx8"; # 2024-04-06
      v56-21-4 = _v "56.21.4" "16ihd84isg09clhyyjf5r7h3s9pcisl8201dya6p0hl6gd15935l"; # 2024-03-08
      v56-2-0 = _v "56.2.0" "0halhmdxyrn5drimyx1hp9sgxyh1qcz9gsb5vn3jmbsx0grv94yn";
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
    chart_url = prom_chart "kube-prometheus-stack";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
  exporters = {
    elasticsearch = rec {
      defaults = {
        name = "prometheus-elasticsearch-exporter";
        namespace = "default";
        version = "5.4.0";
        sha256 = "0rbrq4k0rqvpxx4xhb7sf6m4jdz2giwv6kfmsizbk7fjw05yiilx";
      };
      version = rec {
        _v = hex.k8s._.version chart;
        v5-4-0 = _v "5.4.0" "0rbrq4k0rqvpxx4xhb7sf6m4jdz2giwv6kfmsizbk7fjw05yiilx"; # 2023-12-25
      };
      chart_url = prom_chart "prometheus-elasticsearch-exporter";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
    mongodb = rec {
      defaults = {
        name = "prometheus-mongodb-exporter";
        namespace = "default";
        version = "3.5.0";
        sha256 = "08sg78nqld5h7ynfznf3zn185s9nxsj278xh5p1waw6hxk8993gk";
      };
      version = rec {
        _v = hex.k8s._.version chart;
        v3-5-0 = _v "3.5.0" "08sg78nqld5h7ynfznf3zn185s9nxsj278xh5p1waw6hxk8993gk"; # 2023-12-14
      };
      chart_url = prom_chart "prometheus-mongodb-exporter";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
    mysql = rec {
      defaults = {
        name = "prometheus-mysql-exporter";
        namespace = "default";
        version = "2.4.0";
        sha256 = "0ksm6hxwka2wiw7lzngs27xffm4i2sp9h0i2xqhbviwkd9pppwd4";
      };
      version = rec {
        _v = hex.k8s._.version chart;
        v2-4-0 = _v "2.4.0" "0ksm6hxwka2wiw7lzngs27xffm4i2sp9h0i2xqhbviwkd9pppwd4"; # 2024-01-10
      };
      chart_url = prom_chart "prometheus-mysql-exporter";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
    postgres = rec {
      defaults = {
        name = "prometheus-postgres-exporter";
        namespace = "default";
        version = "5.3.0";
        sha256 = "0zimga6ya5f2cf736yc0svmd8bs7v7nhrahsm56xzj26r89cwrh9";
      };
      version = rec {
        _v = hex.k8s._.version chart;
        v5-3-0 = _v "5.3.0" "0zimga6ya5f2cf736yc0svmd8bs7v7nhrahsm56xzj26r89cwrh9";
      };
      chart_url = prom_chart "prometheus-postgres-exporter";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
    redis = rec {
      defaults = {
        name = "prometheus-redis-exporter";
        namespace = "default";
        version = "6.1.1";
        sha256 = "0im2gkiijz0ggsnw39my7j0w1f8m7msd5hkr2930i2p2cn5mmp8j";
      };
      version = rec {
        _v = hex.k8s._.version chart;
        v6-1-1 = _v "6.1.1" "0im2gkiijz0ggsnw39my7j0w1f8m7msd5hkr2930i2p2cn5mmp8j"; # 2024-01-30
      };
      chart_url = prom_chart "prometheus-redis-exporter";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
  };
}
