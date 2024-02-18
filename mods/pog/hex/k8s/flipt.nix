{ hex, ... }:
let
  name = "flipt";
  flipt = rec {
    defaults = {
      inherit name;
      namespace = name;
      version = "0.53.1";
      sha256 = "1wgmnbms95rnjd3dq09dwiiwdnrq95pc9n0v6763b5j9s7yf7alc";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-53-1;
      v0-53-1 = _v "0.53.1" "1wgmnbms95rnjd3dq09dwiiwdnrq95pc9n0v6763b5j9s7yf7alc"; # 2024-02-12
      v0-53-0 = _v "0.53.0" "1fdq507fjinancnfgy0qkfx91z7p9yp84qxxld4khr0fh791bfv2"; # 2024-02-09
      v0-52-0 = _v "0.52.0" "1p1hzwz181x7dvyln98qdjfswkrnkk122m7z0vm1sd7ycazbv9wz"; # 2024-01-23
      v0-51-0 = _v "0.51.0" "0vnb965a10s8qzjgr11ph40g6ji1cnm6j93rs0qshnn4jkg13553";
    };
    chart_url = version: "https://github.com/flipt-io/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
flipt
