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
      _v = hex.k8s._.version chart;
      latest = v3-0-0;
      v3-0-0 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://hub.jupyter.org/helm-chart/jupyterhub-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
jupyterhub
