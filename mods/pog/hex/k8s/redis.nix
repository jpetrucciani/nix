{ hex, ... }:
let
  name = "redis-operator";
  redis = rec {
    defaults = {
      inherit name;
      namespace = name;
      version = "3.3.0";
      sha256 = "1qd372v7705hl22j86ik60q0jvwlwx7mpslqy16ms03c7gf63mwl";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v3-3-0;
      v3-3-0 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://github.com/spotahome/${name}/releases/download/Chart-${version}/${name}-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
redis
