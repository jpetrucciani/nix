{ hex, ... }:
let
  # https://github.com/StackStorm/stackstorm-k8s
  stackstorm = rec {
    defaults = {
      name = "stackstorm";
      namespace = "stackstorm";
      version = "0.100.0";
      sha256 = "1irm8wbhpp14cbgchm8d368hd194bkldymffjym7wqlc87an7prs";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v0-100-0;
      v0-100-0 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://helm.stackstorm.com/stackstorm-ha-${version}.tgz";
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
stackstorm
