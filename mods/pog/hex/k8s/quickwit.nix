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
      latest = v0-7-0;
      v0-7-0 = _v "0.7.0" "150h80cyxlhrxsh0sr5sbjpkvqm1qlxzkfcaym43cqyfjrlxr7x7"; # 2024-08-01
    };
    chart_url = version: "https://github.com/quickwit-oss/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
    chart = hex.k8s._.chart {
      inherit defaults chart_url;
    };
  };
in
quickwit
