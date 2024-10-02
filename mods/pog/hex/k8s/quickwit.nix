# [quickwit](https://github.com/quickwit-oss/quickwit) is a Cloud-native search engine for observability. An open-source alternative to Datadog, Elasticsearch, Loki, and Tempo
{ hex, ... }:
let
  name = "quickwit";

  quickwit = rec {
    defaults = {
      inherit name;
      namespace = name;
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-7-1;
      v0-7-1 = _v "0.7.1" "0hcn0z9cpif930cdr47igca5qnfm8iq6mvh83hx4zk98k2lbq2x6"; # 2024-09-18
    };
    chart_url = version: "https://github.com/quickwit-oss/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
    chart = hex.k8s._.chart {
      inherit defaults chart_url;
    };
  };
in
quickwit
