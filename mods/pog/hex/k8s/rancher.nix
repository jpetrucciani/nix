{ hex, ... }:
let
  inherit (hex) toYAML;

  rancher = rec {
    defaults = {
      name = "rancher";
      namespace = "rancher";
      version = "2.6.8";
      sha256 = "1r176y195prfil61fzdgplcwfvish65pjx2nlylxj2az2acr143n";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      v2-6-4 = _v "2.6.4" "0ggfhgyn01nz4qb0izyihca3hzjc0v4292z9gnji37f82sbkqvcn";
      v2-6-8 = _v defaults.version defaults.sha256;
      latest = v2-6-8;
    };
    chart_url = version: "https://releases.rancher.com/server-charts/stable/rancher-${version}.tgz";
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
rancher
