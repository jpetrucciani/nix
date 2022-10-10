{ hex, ... }:
let
  inherit (hex) toYAML;

  datadog = rec {
    defaults = {
      name = "datadog";
      namespace = "default";
      version = "3.1.9";
      sha256 = "1wryym5v8pr70r3fs4i4y2mq8dihla07djnyis0q68l1j3m27mzs";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      v3-1-3 = _v "3.1.3" "004mr6jj046dqwfbd4zrs6qj8wqh9l8hwvrym9akdqr5fkilizzb";
      v3-1-9 = _v defaults.version defaults.sha256;
      latest = v3-1-9;
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
