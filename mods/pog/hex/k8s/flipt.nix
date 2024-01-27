{ hex, ... }:
let
  name = "flipt";
  flipt = rec {
    defaults = {
      inherit name;
      namespace = name;
      version = "0.52.0";
      sha256 = "1p1hzwz181x7dvyln98qdjfswkrnkk122m7z0vm1sd7ycazbv9wz";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-52-0;
      v0-52-0 = _v defaults.version defaults.sha256; # 2024-01-23
      v0-51-0 = _v "0.51.0" "0vnb965a10s8qzjgr11ph40g6ji1cnm6j93rs0qshnn4jkg13553";
    };
    chart_url = version: "https://github.com/flipt-io/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
flipt
