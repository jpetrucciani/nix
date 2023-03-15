{ hex, ... }:
let
  robusta = rec {
    defaults = {
      name = "robusta";
      namespace = "robusta";
      version = "0.10.13";
      sha256 = "000yyggbvczh2fh6kj68cpikjgx7y08g57472m2ffzkqn80v67bz";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v0-10-13;
      v0-10-13 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://robusta-charts.storage.googleapis.com/robusta-${version}.tgz";
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
robusta
