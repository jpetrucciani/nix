{ hex, ... }:
let
  inherit (hex) toYAML;

  # 
  infisical = rec {
    defaults = {
      name = "infisical";
      namespace = "infisical";
      version = "0.1.3";
      sha256 = "00yjnj4s5hk2ibchsaw4qql0rccsj9rqh2s4769qq4lkhapdnrc6";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v0-1-3;
      v0-1-3 = _v defaults.version defaults.sha256;
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
