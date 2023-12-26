{ hex, ... }:
let
  name = "otf";
  otf = rec {
    defaults = {
      inherit name;
      namespace = name;
      version = "0.3.13";
      sha256 = "0769y1554cgajpa19987xwwpg4pikgk8c0l69s6b5kpyyw3k2cjc";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v0-3-13;
      v0-3-13 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://github.com/jpetrucciani/otf-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
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
otf
