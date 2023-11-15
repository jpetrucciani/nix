{ hex, ... }:
let
  datadog = rec {
    defaults = {
      name = "datadog";
      namespace = "default";
      version = "3.45.0";
      sha256 = "0z306k1v4zna4jp96yr9sh3aq9hqx5riapxymd3w8zq440n0w2h8";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v3-45-0;
      v3-45-0 = _v defaults.version defaults.sha256;
      v3-1-9 = _v "3.1.9" "1wryym5v8pr70r3fs4i4y2mq8dihla07djnyis0q68l1j3m27mzs";
      v3-1-3 = _v "3.1.3" "004mr6jj046dqwfbd4zrs6qj8wqh9l8hwvrym9akdqr5fkilizzb";
    };
    chart_url = version: hex.k8s.helm.charts.url.github {
      inherit version;
      org = "DataDog";
      repo = "helm-charts";
      repoName = "datadog";
    };
    chart =
      { name ? defaults.name
      , namespace ? defaults.namespace
      , values ? [ ]
      , sets ? [ ]
      , version ? defaults.version
      , sha256 ? defaults.sha256
      , forceNamespace ? true
      , extraFlags ? [ ]
      }: hex.k8s.helm.build {
        inherit name namespace sha256 values version forceNamespace sets extraFlags;
        url = chart_url version;
      };
  };
in
datadog
