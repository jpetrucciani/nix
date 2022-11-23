{ hex, ... }:
let
  inherit (hex) toYAML;

  authentik = rec {
    defaults = {
      name = "authentik";
      namespace = "default";
      version = "2022.11.0";
      sha256 = "1a4h4kap0h3w3qqknnbm2frk9cs50zk1cpy8lwpvnv0i9fh14l1l";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v2022-11-0;
      v2022-11-0 = _v defaults.version defaults.sha256;
      v2022-10-0 = _v "2022.10.0" "0k6m6zi0pjihl1wqzrm7akymzswlqbg9qpf9f6fz3wicj63cj6bv";
      v2022-9-0 = _v "2022.9.0" "1r8hnacfl70ih5d3vqp6zk2c94gffqimmj4cw5g4lbri65gzgl1l";
      v2022-7-3 = _v "2022.7.3" "05vv6wjyf1vkfy2qmp4yshb4pxyg246fkpc6v6gp3b5h5y55ds30";
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
        inherit name namespace sha256 values version forceNamespace sets extraFlags;
        url = chart_url version;
      };
  };
in
authentik
