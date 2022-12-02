{ hex, ... }:
let
  inherit (hex) toYAML;

  # https://github.com/SigNoz/charts/
  signoz = rec {
    defaults = {
      name = "signoz";
      namespace = "signoz";
      version = "0.5.1";
      sha256 = "1sk50lrkyh9zrjrxqdzl2bvh9wrxv4ccc5m1ijn6h9wlsik35aqb";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v0-5-1;
      v0-5-1 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://github.com/SigNoz/charts/releases/download/signoz-${version}/signoz-${version}.tgz";
    chart =
      { name ? defaults.name
      , namespace ? defaults.namespace
      , values ? [ ]
      , sets ? [ ]
      , version ? defaults.version
      , sha256 ? defaults.sha256
      , forceNamespace ? true
      , extraFlags ? [ hex.k8s.helm.constants.flags.create-namespace ]
      , sortYaml ? false
      }: hex.k8s.helm.build {
        inherit name namespace values sets version sha256 extraFlags forceNamespace sortYaml;
        url = chart_url version;
      };
  };
in
signoz
