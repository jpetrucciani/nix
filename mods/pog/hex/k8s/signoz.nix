{ hex, ... }:
let
  # https://github.com/SigNoz/charts/
  signoz = rec {
    defaults = {
      name = "signoz";
      namespace = "signoz";
      version = "0.11.2";
      sha256 = "027hjk7awivh9wzcgq959595hsbaj9l83zz97lv3sk4n9lisbfaj";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-11-2;
      v0-11-2 = _v defaults.version defaults.sha256;
      v0-5-1 = _v "0.5.1" "1sk50lrkyh9zrjrxqdzl2bvh9wrxv4ccc5m1ijn6h9wlsik35aqb";
    };
    chart_url = version: "https://github.com/SigNoz/charts/releases/download/signoz-${version}/signoz-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
signoz
