{ hex, ... }:
let
  name = "otf";
  otf = rec {
    defaults = {
      inherit name;
      namespace = name;
      version = "0.3.13";
      sha256 = "0769y1554cgajpa19987xwwpg4pikgk8c0l69s6b5kpyyw3k2cjc";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-3-13;
      v0-3-13 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://github.com/jpetrucciani/otf-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
otf
