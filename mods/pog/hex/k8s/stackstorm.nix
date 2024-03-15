# K8s Helm module for running a [StackStorm](https://stackstorm.com) cluster in HA mode.
{ hex, ... }:
let
  # https://github.com/StackStorm/stackstorm-k8s
  stackstorm = rec {
    defaults = {
      name = "stackstorm";
      namespace = "stackstorm";
      version = "0.100.0";
      sha256 = "1irm8wbhpp14cbgchm8d368hd194bkldymffjym7wqlc87an7prs";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-100-0;
      v0-100-0 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://helm.stackstorm.com/stackstorm-ha-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
stackstorm
