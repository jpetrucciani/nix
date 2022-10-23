{ hex, pkgs, ... }:
let
  inherit (hex) toYAML;

  gitlab-runner = rec {
    defaults = {
      name = "gitlab-runner";
      namespace = "gitlab";
      version = "0.46.0";
      sha256 = "01kxhsrqrwbjfq44dwjpq35jj4wzass7zcbb9lqaiblxc22jrgw7";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      v0-45-0 = _v "0.45.0" "03hk3rfz67in5cv01dmvv1cwd3df0rv3d0vwgki69hmyxgmlrq58";
      v0-45-1 = _v "0.45.1" "0pzgpa29f7lxcsf3jd11jib6fb65f5yj76jn2np8a2nlip58v3lz";
      v0-46-0 = _v defaults.version defaults.sha256;
      latest = v0-46-0;
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
