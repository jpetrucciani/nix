# This module contains a [sonarqube](https://github.com/SonarSource/helm-chart-sonarqube/tree/master/charts/sonarqube) helm chart
{ hex, ... }:
let
  inherit (hex.pkgs.lib) head splitString;
  stripPlus = x: head (splitString "+" x);
  defaults = {
    name = "sonarqube";
    namespace = "sonarqube";
  };
  chart = hex.k8s._.chart {
    inherit defaults chart_url;
  };
  chart_url = version: "https://github.com/SonarSource/helm-chart-sonarqube/releases/download/sonarqube-${stripPlus version}/sonarqube-${version}.tgz";
in
{
  inherit chart chart_url defaults;
  version = rec {
    _v = hex.k8s._.version chart;
    latest = v10-6-1;
    v10-6-1 = _v "10.6.1+3163" "0nqmmd7gaisjwbznfj5wf0wykw20qidgmgcxpz3nqkhh778x9s96"; # 2024-07-16
  };
}
