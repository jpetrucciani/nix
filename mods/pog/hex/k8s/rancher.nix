# [rancher](https://github.com/rancher/rancher) is an open-source multi-cluster orchestration platform
{ hex, ... }:
let
  rancher = rec {
    defaults = {
      name = "rancher";
      namespace = "rancher";
      version = "2.6.8";
      sha256 = "1r176y195prfil61fzdgplcwfvish65pjx2nlylxj2az2acr143n";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v2-6-8;
      v2-6-8 = _v defaults.version defaults.sha256;
      v2-6-4 = _v "2.6.4" "0ggfhgyn01nz4qb0izyihca3hzjc0v4292z9gnji37f82sbkqvcn";
    };
    chart_url = version: "https://releases.rancher.com/server-charts/stable/rancher-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
rancher
