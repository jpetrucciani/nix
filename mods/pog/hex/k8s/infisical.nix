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
      _v = hex.k8s._.version chart;
      latest = v0-1-13;
      v0-1-13 = _v "0.1.13" "0gn5085zmk6zqka1vjbfyrd7xkd8mq5hzkhiy4gj7sd8qi9xkaa2";
      v0-1-3 = _v "0.1.3" "00yjnj4s5hk2ibchsaw4qql0rccsj9rqh2s4769qq4lkhapdnrc6";
    };
    chart_url = version: "https://dl.cloudsmith.io/public/infisical/helm-charts/helm/charts/infisical-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
infisical
