{ hex, ... }:
let
  name = "terrakube";
  terrakube = rec {
    defaults = {
      inherit name;
      namespace = name;
      version = "3.10.2";
      sha256 = "0gsr7w3lvnqzqvw22bl0w7s3isb5z0hrx0nf7h6xc1a94r583kfq";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v3-10-2;
      v3-10-2 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://github.com/AzBuilder/terrakube-helm-chart/releases/download/${name}-${version}/${name}-${version}.tgz";
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
      , postRender ? ""
      }: hex.k8s.helm.build {
        inherit name namespace values sets version sha256 extraFlags forceNamespace sortYaml postRender;
        url = chart_url version;
      };
  };
in
terrakube
