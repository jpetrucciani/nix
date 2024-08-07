# This module contains the [signoz](https://github.com/SigNoz/signoz) helm chart
{ hex, ... }:
let
  # https://github.com/SigNoz/charts/
  signoz = rec {
    defaults = {
      name = "signoz";
      namespace = "signoz";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-45-0;
      v0-45-0 = _v "0.45.0" "1lsg06fbgc2ka6568dlm88na1p0w89djk6ryg2zccyxacq174sfr"; # 2024-07-03
      v0-11-2 = _v defaults.version defaults.sha256;
      v0-5-1 = _v "0.5.1" "1sk50lrkyh9zrjrxqdzl2bvh9wrxv4ccc5m1ijn6h9wlsik35aqb";
    };
    chart_url = version: "https://github.com/SigNoz/charts/releases/download/signoz-${version}/signoz-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
signoz
