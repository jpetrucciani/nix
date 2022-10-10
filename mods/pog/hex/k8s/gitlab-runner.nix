{ hex, pkgs, ... }:
let
  inherit (hex) toYAML;
  gitlab-runner = rec {
    defaults = {
      name = "gitlab-runner";
      namespace = "gitlab";
      version = "0.45.0";
      sha256 = "03hk3rfz67in5cv01dmvv1cwd3df0rv3d0vwgki69hmyxgmlrq58";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      v0-45-0 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://gitlab-charts.s3.amazonaws.com/gitlab-runner-${version}.tgz";
    chart =
      { name ? defaults.name
      , namespace ? defaults.namespace
      , values ? [ ]
      , sets ? [ ]
      , version ? defaults.version
      , sha256 ? defaults.sha256
      , forceNamespace ? true
      , extraFlags ? [ hex.k8s.helm.constants.flags.create-namespace ]
      }: hex.k8s.helm.build {
        inherit name namespace sha256 values version forceNamespace sets;
        url = chart_url version;
      };
  };
in
gitlab-runner
