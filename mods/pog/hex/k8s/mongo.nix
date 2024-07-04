# [mongodb-operator](https://github.com/mongodb/mongodb-kubernetes-operator) is a way to deploy and maintain mongodb deployments on k8s
{ hex, ... }:
let
  name = "mongo-operator";
  mongo = rec {
    defaults = {
      inherit name;
      namespace = name;
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-10-0;
      v0-10-0 = _v "0.10.0" "1zm6di9r6kg0prm6sahqrxj7r84qqiz25kaca1ysdsv53pqi3v1r"; # 2024-06-27
      v0-9-0 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://github.com/mongodb/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
mongo
