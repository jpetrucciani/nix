# [plane](https://github.com/makeplane/plane) is an Open Source JIRA, Linear and Asana Alternative
{ hex, ... }:
let
  name = "plane";

  plane = rec {
    defaults = {
      inherit name;
      namespace = name;
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v1-0-19;
      v1-0-19 = _v "1.0.19" "0rk18nfnq9g4b377lvjzrbf44phyxvd2m06h3a8ylrwdk52ffb8f"; # 2024-06-17
    };
    chart_url = version: "https://github.com/makeplane/helm-charts/releases/download/${name}-ce-${version}/${name}-ce-${version}.tgz";
    chart = hex.k8s._.chart {
      inherit defaults chart_url;
    };
  };
in
plane
