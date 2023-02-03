{ hex, ... }:
let
  infisical = rec {
    defaults = {
      name = "infisical";
      namespace = "infisical";
      version = "0.1.13";
      sha256 = "0gn5085zmk6zqka1vjbfyrd7xkd8mq5hzkhiy4gj7sd8qi9xkaa2";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v0-1-13;
      v0-1-13 = _v "0.1.13" "0gn5085zmk6zqka1vjbfyrd7xkd8mq5hzkhiy4gj7sd8qi9xkaa2";
      v0-1-3 = _v "0.1.3" "00yjnj4s5hk2ibchsaw4qql0rccsj9rqh2s4769qq4lkhapdnrc6";
    };
    chart_url = version: "";
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
infisical
