{ hex, ... }:
let
  # https://github.com/SigNoz/charts/
  signoz = rec {
    defaults = {
      name = "signoz";
      namespace = "signoz";
      version = "0.11.2";
      sha256 = "027hjk7awivh9wzcgq959595hsbaj9l83zz97lv3sk4n9lisbfaj";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v0-5-1;
      v0-11-2 = _v defaults.version defaults.sha256;
      v0-5-1 = _v "0.5.1" "1sk50lrkyh9zrjrxqdzl2bvh9wrxv4ccc5m1ijn6h9wlsik35aqb";
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
