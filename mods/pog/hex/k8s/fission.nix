# [fission](https://github.com/fission/fission) is a serverless function platform for k8s
{ hex, ... }:
let
  name = "fission";
  fission = rec {
    defaults = {
      inherit name;
      namespace = name;
      version = "1.20.0";
      sha256 = "1cqxsjmrbaljxvkzbi6m4wx5zhmajw18prdn4yl2zhlh9bgvjpxy";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v1-20-0;
      v1-20-0 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://github.com/fission/fission-charts/releases/download/${name}-all-${version}/${name}-all-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
fission
