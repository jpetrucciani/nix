{ hex, ... }:
let
  name = "fission";
  fission = rec {
    defaults = {
      inherit name;
      namespace = name;
      version = "1.20.0";
      sha256 = "1cqxsjmrbaljxvkzbi6m4wx5zhmajw18prdn4yl2zhlh9bgvjpxy";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v1-20-0;
      v1-20-0 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://github.com/fission/fission-charts/releases/download/${name}-all-${version}/${name}-all-${version}.tgz";
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
      , preRender ? ""
      , postRender ? ""
      }: hex.k8s.helm.build {
        inherit name namespace values sets version sha256 extraFlags forceNamespace sortYaml preRender postRender;
        url = chart_url version;
      };
  };
in
fission
