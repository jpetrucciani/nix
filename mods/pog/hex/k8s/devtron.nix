{ hex, ... }:
let
  devtron = rec {
    defaults = {
      name = "devtron";
      namespace = "devtron";
      version = "0.22.48";
      sha256 = "1xfh9gzjsk7p7gndf4p2v856bb8a0105sli1nndsll19xy2mnhil";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v0-22-48;
      v0-22-48 = _v defaults.version defaults.sha256;

    };
    chart_url = version: "https://github.com/devtron-labs/charts/releases/download/devtron-operator-${version}/devtron-operator-${version}.tgz";
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
devtron
