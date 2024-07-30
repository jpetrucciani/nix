# [tofutf](https://github.com/tofutf/tofutf) is an open source terraform cloud alternative
{ hex, ... }:
let
  name = "tofutf";
  tofutf = rec {
    defaults = {
      inherit name;
      namespace = name;
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-9-1;
      v0-9-1 = _v "v0.9.1" "sha256-sPGWM4LYH+IWJw3A1Btit2Od/ToZGDhnJcHnbhA7F8w=";
    };
    chart_url = version: "oci://ghcr.io/tofutf/tofutf/charts/tofutf:${version}";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
tofutf
