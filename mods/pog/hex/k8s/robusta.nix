# [robusta](https://github.com/robusta-dev/robusta) is a Kubernetes observability and automation, with an awesome Prometheus integration
{ hex, ... }:
let
  robusta = rec {
    defaults = {
      name = "robusta";
      namespace = "robusta";
      version = "0.10.13";
      sha256 = "000yyggbvczh2fh6kj68cpikjgx7y08g57472m2ffzkqn80v67bz";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-10-13;
      v0-10-13 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://robusta-charts.storage.googleapis.com/robusta-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
robusta
