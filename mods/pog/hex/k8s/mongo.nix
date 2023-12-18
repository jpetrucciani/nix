{ hex, ... }:
let
  name = "mongo-operator";
  mongo = rec {
    defaults = {
      inherit name;
      namespace = name;
      version = "0.9.0";
      sha256 = "17rrridvqsc9q3ck5smyds60vy5sbyln0bgnxs1i97z2l65czw9s";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v0-9-0;
      v0-9-0 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://github.com/mongodb/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
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
mongo
