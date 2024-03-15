# a hex module for [airbyte](https://github.com/airbytehq/airbyte), an ETL pipeline tool
{ hex, ... }:
let
  # https://github.com/airbytehq/airbyte-platform/blob/main/charts/airbyte/values.yaml
  airbyte = rec {
    defaults = {
      name = "airbyte";
      namespace = "airbyte";
      version = "0.45.12";
      sha256 = "0cpy2hjlka84lfy8mxf5kng6nhl05dknnmy0ax9nx86af3z62hi8";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-45-12;
      v0-45-12 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://airbytehq.github.io/helm-charts/airbyte-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
airbyte
