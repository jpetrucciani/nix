{ hex, ... }:
let
  # https://github.com/jupyterhub/zero-to-jupyterhub-k8s/tags
  # https://hub.jupyter.org/helm-chart/
  jupyterhub = rec {
    defaults = {
      name = "jupyterhub";
      namespace = "jupyterhub";
      version = "3.0.0";
      sha256 = "0w3m7k0xgha59n50999nhgwyap8dgw3fz764q5l5sgh18kq0z8px";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v3-0-0;
      v3-0-0 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://hub.jupyter.org/helm-chart/jupyterhub-${version}.tgz";
    chart =
      { name ? defaults.name
      , namespace ? defaults.namespace
      , values ? [ ]
      , sets ? [ ]
      , version ? defaults.version
      , sha256 ? defaults.sha256
      , forceNamespace ? true
      , extraFlags ? [
          hex.k8s.helm.constants.flags.create-namespace
          "--version=${version}"
        ]
      , sortYaml ? false
      }: hex.k8s.helm.build {
        inherit name namespace values sets version sha256 extraFlags forceNamespace sortYaml;
        url = chart_url version;
      };
  };
in
jupyterhub
