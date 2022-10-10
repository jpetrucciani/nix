{ hex, pkgs, ... }:
let
  inherit (hex) toYAML;
  authentik = rec {
    defaults = {
      name = "authentik";
      namespace = "default";
      version = "2022.9.0";
      sha256 = "1r8hnacfl70ih5d3vqp6zk2c94gffqimmj4cw5g4lbri65gzgl1l";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      v2022-7-3 = _v "2022.7.3" "05vv6wjyf1vkfy2qmp4yshb4pxyg246fkpc6v6gp3b5h5y55ds30";
      v2022-9-0 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://github.com/goauthentik/helm/releases/download/authentik-${version}/authentik-${version}.tgz";
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
authentik
