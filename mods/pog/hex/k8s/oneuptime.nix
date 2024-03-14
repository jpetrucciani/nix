{ hex, ... }:
let
  name = "oneuptime";
  oneuptime = rec {
    defaults = {
      inherit name;
      namespace = name;
      version = "7.0.1733";
      sha256 = "0pgnyv72g1bjmh4r08mrxn55l7si00sxy4k4mkqyapawh9qsi1jb";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v7-0-1733;
      v7-0-1733 = _v "7.0.1733" "0pgnyv72g1bjmh4r08mrxn55l7si00sxy4k4mkqyapawh9qsi1jb"; # 2024-03-13
    };
    chart_url = version: "https://helm-chart.oneuptime.com/${name}-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
oneuptime
