{ hex, ... }:
let
  # https://github.com/jupyterhub/zero-to-jupyterhub-k8s/tags
  # https://hub.jupyter.org/helm-chart/
  jupyterhub = rec {
    defaults = {
      name = "jupyterhub";
      namespace = "jupyterhub";
      version = "3.2.1";
      sha256 = "144bbsb0j0zpfkj8bki0kikjjj1wvy98b250cdzq2rh8mkpcfyfd";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v3-2-1;
      v3-2-1 = _v "3.2.1" "144bbsb0j0zpfkj8bki0kikjjj1wvy98b250cdzq2rh8mkpcfyfd"; # 2023-11-27
      v3-2-0 = _v "3.2.0" "1qzc8q8wjwjbm2ymdgxjsqyfkmqvjbnq4450dsfngp9adss1gslx"; # 2023-11-27
      v3-1-0 = _v "3.1.0" "1aj4s6ykchfl59y5nid86kj389d6njl3ndp68gy5lm9wphvwiqw3"; # 2023-09-29
      v3-0-3 = _v "3.0.3" "04k5cj6a0wqw45bhspcd6q662zbx6539d1wb0r81pdlssmjkf6pl"; # 2023-08-29
      v3-0-2 = _v "3.0.2" "1l9r3sv74mnpyqv2lrizf714ai2znbvlqs9hxag0hymx3l8hayg1"; # 2023-08-17
      v3-0-1 = _v "3.0.1" "1q7zscj5c92gy30bzklnx58v5y0zwx5hcxz5vxrmw7i9h6zqbqgw"; # 2023-08-15
      v3-0-0 = _v "3.0.0" "0w3m7k0xgha59n50999nhgwyap8dgw3fz764q5l5sgh18kq0z8px"; # 2023-08-11
    };
    chart_url = version: "https://hub.jupyter.org/helm-chart/jupyterhub-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
jupyterhub
