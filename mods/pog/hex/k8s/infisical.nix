# This module contains an [infisical](https://github.com/Infisical/infisical) helm chart
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
      latest = v0-4-2;
      v0-4-2 = _v "0.4.2" "12j1xkgvp1s5pigvfyqb367bvhl2hfnq4jxpfvmgj3148ckipq86"; # 2024-05-07
      v0-3-5 = _v "0.3.5" "12d4wqhiai1sccn5xzrdrbblikif2y91h2fyls6q4sqy28077wzc"; # 2023-10-12
      v0-1-13 = _v "0.1.13" "0gn5085zmk6zqka1vjbfyrd7xkd8mq5hzkhiy4gj7sd8qi9xkaa2";
      v0-1-3 = _v "0.1.3" "00yjnj4s5hk2ibchsaw4qql0rccsj9rqh2s4769qq4lkhapdnrc6";
    };
    chart_url = version: "https://dl.cloudsmith.io/public/infisical/helm-charts/helm/charts/infisical-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
infisical
