# [fission](https://github.com/fission/fission) is a serverless function platform for k8s
{ hex, ... }:
let
  name = "fission";
  fission = rec {
    defaults = {
      inherit name;
      namespace = name;
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v1-20-2;
      v1-20-2 = _v "1.20.2" "13pzylgllcb83yanxnmz6kg1bdhy80zkxbdc98ckqz5k15wy7f6p"; # 2024-05-27
      v1-20-1 = _v "1.20.1" "0yrba33qh6dyqgam31lx3jr4b7ah9gfcbc25b32ffivmp6fdwdgs"; # 2024-01-14
      v1-20-0 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://github.com/fission/fission-charts/releases/download/${name}-all-${version}/${name}-all-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
fission
