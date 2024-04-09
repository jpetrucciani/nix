# This module contains helm charts under the [grafana](https://grafana.com/) observability umbrella. This includes things like [loki](https://github.com/grafana/loki), [mimir](https://github.com/grafana/mimir), and [oncall](https://github.com/grafana/oncall).
{ hex, ... }:
let
  _chart_url = { name, version, prefix ? "" }: "https://github.com/grafana/helm-charts/releases/download/${prefix}${name}-${version}/${name}-${version}.tgz";
  _chart = { defaults, prefix ? "" }:
    { name ? defaults.name
    , chart_name ? defaults.chart_name
    , namespace ? defaults.namespace
    , values ? [ ]
    , sets ? [ ]
    , version ? defaults.version
    , sha256 ? defaults.sha256
    , forceNamespace ? true
    , extraFlags ? [ hex.k8s.helm.constants.flags.create-namespace ]
    , preRender ? ""
    , postRender ? ""
    }: hex.k8s.helm.build {
      inherit name namespace sha256 values version forceNamespace sets extraFlags preRender postRender;
      url = _chart_url { inherit prefix version; name = chart_name; };
    };
  loki = rec {
    defaults = {
      name = "loki";
      chart_name = "loki";
      namespace = "loki";
      version = "6.0.0";
      sha256 = "08hy2fwr6rlqc0cf6g815fly45nmf1kv3ngfgmy4k2jyf5rd8z50";
    };
    chart = _chart { inherit defaults; prefix = "helm-"; };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v6-0-0;
      v6-0-0 = _v "6.0.0" "08hy2fwr6rlqc0cf6g815fly45nmf1kv3ngfgmy4k2jyf5rd8z50"; # 2024-04-08
      v5-47-2 = _v "5.47.2" "0wax65hy9gc56gch0ypgm10a9qya5r6ygnnv3klna1a94nf32d4n"; # 2024-03-28
      v5-47-1 = _v "5.47.1" "171iwpniwc7q35vd5vgz9jzd8j24az4f3gsxgdlp1a4r5y5kxjm9"; # 2024-03-22
      v5-44-4 = _v "5.44.4" "124fms4hpqyr40a9jb5bvh48m5dvqi7m7xyq234c7d2jbqm0w201"; # 2024-03-18
      v5-43-7 = _v "5.43.7" "1n8mbv198kjx4drbvv6alh3l2vr86spvv3zik99ppajfpi8pv0rv"; # 2024-03-14
      v5-42-3 = _v "5.42.3" "0qkbivgpwbx7ffwh7szs725qhvla2bh1h66ja5zdnyry5wagcz8k"; # 2024-02-14
      v5-36-3 = _v "5.36.3" "15441r0k0mjn3hc9276pi6ijrs5czpy7p69610v3fi8dz8h1fnvk";
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
      _v = hex.k8s._.version chart;
      latest = v5-1-2;
      v5-1-2 = _v "5.1.2" "0frz4fs0za92flb81cgpxhjrkrsmypykz6ynn5j4z1vafqs4ckhq";
    };
  };
  oncall = rec {
    defaults = {
      name = "oncall";
      chart_name = "oncall";
      namespace = "oncall";
      version = "1.3.113";
      sha256 = "0yqlsfhmcabppcczad6hdlaav2nxi9z9i4nn51h1rdh6w7g6xc2s";
    };
    chart = _chart { inherit defaults; };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v1-3-113;
      v1-3-113 = _v "1.3.113" "0yqlsfhmcabppcczad6hdlaav2nxi9z9i4nn51h1rdh6w7g6xc2s"; # 2024-03-21
      v1-3-45 = _v "1.3.45" "1xrrryq5bvvbpxplpnwqn6yr0c1sp4k2idib5hybky8sczyfjjyn";
    };
  };
in
{ inherit loki mimir oncall; }
