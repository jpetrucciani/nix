{ hex, ... }:
let
  name = "redis-operator";
  redis = rec {
    defaults = {
      inherit name;
      namespace = name;
      version = "3.3.0";
      sha256 = "1qd372v7705hl22j86ik60q0jvwlwx7mpslqy16ms03c7gf63mwl";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v3-3-0;
      v3-3-0 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://github.com/spotahome/${name}/releases/download/Chart-${version}/${name}-${version}.tgz";
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
redis
