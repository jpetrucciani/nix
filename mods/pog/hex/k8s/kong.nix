# This module contains a [kong ingress controller](https://github.com/Kong/kubernetes-ingress-controller) helm chart
{ hex, ... }:
let
  kong = rec {
    defaults = {
      name = "kong-ingress";
      namespace = "kong";
      # apiVersions = "gateway.networking.k8s.io/v1";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-14-0;
      v0-14-0 = _v "0.14.0" "0ik3ws4blsqfzvdr8sbz4xh8852r5vaz0rv4255093h0wxk8wcij"; # 2024-09-02
      v0-13-1 = _v "0.13.1" "0mhhzpza3mhz29lsb8f01g92l2n4li58ig15ljy5k9asn3cixjxs"; # 2024-06-19
      v0-12-0 = _v "0.12.0" "07sphskl4n6dh0dsnffd75dszqxcx7szigacx6917h5gq9565i06"; # 2024-02-29
    };
    chart_url = version: "https://github.com/Kong/charts/releases/download/ingress-${version}/ingress-${version}.tgz";
    chart = hex.k8s._.chart {
      inherit defaults chart_url;
    };
  };
in
kong
