# [mongodb-operator](https://github.com/mongodb/mongodb-kubernetes-operator) is a way to deploy and maintain mongodb deployments on k8s
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
      _v = hex.k8s._.version chart;
      latest = v0-9-0;
      v0-9-0 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://github.com/mongodb/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
mongo
