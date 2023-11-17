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
      version = "5.36.3";
      sha256 = "15441r0k0mjn3hc9276pi6ijrs5czpy7p69610v3fi8dz8h1fnvk";
    };
    chart = _chart { inherit defaults; prefix = "helm-"; };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v5-36-3;
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
