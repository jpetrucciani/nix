{ hex, ... }:
let
  _chart_url = { name, version }: "https://github.com/grafana/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
  _chart = { defaults }:
    { name ? defaults.name
    , chart_name ? defaults.chart_name
    , namespace ? defaults.namespace
    , values ? [ ]
    , sets ? [ ]
    , version ? defaults.version
    , sha256 ? defaults.sha256
    , forceNamespace ? true
    , extraFlags ? [ hex.k8s.helm.constants.flags.create-namespace ]
    }: hex.k8s.helm.build {
      inherit name namespace sha256 values version forceNamespace sets extraFlags;
      url = _chart_url { inherit version; name = chart_name; };
    };
  loki = rec {
    defaults = {
      name = "loki";
      chart_name = "loki-simple-scalable";
      namespace = "loki";
      version = "1.8.11";
      sha256 = "0h9nzls8g9gbh371y2z41lpc4v2yyd515dccqbrczd2dlziqzsm8";
    };
    chart = _chart { inherit defaults; };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v1-8-11;
      v1-8-11 = _v "1.8.11" "0v0gd492670d659d8x2m66n1vxpjh48fjapc6zhcl6qncmw0grxx";
    };
  };
  mimir = rec {
    defaults = {
      name = "mimir";
      chart_name = "mimir-distributed";
      namespace = "mimir";
      version = "5.1.2";
      sha256 = "0frz4fs0za92flb81cgpxhjrkrsmypykz6ynn5j4z1vafqs4ckhq";
    };
    chart = _chart { inherit defaults; };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v5-1-2;
      v5-1-2 = _v "5.1.2" "0frz4fs0za92flb81cgpxhjrkrsmypykz6ynn5j4z1vafqs4ckhq";
    };
  };
  oncall = rec {
    defaults = {
      name = "oncall";
      chart_name = "oncall";
      namespace = "oncall";
      version = "1.3.45";
      sha256 = "1xrrryq5bvvbpxplpnwqn6yr0c1sp4k2idib5hybky8sczyfjjyn";
    };
    chart = _chart { inherit defaults; };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v1-3-45;
      v1-3-45 = _v "1.3.45" "1xrrryq5bvvbpxplpnwqn6yr0c1sp4k2idib5hybky8sczyfjjyn";
    };
  };
in
{ inherit loki mimir oncall; }
