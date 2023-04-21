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
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v0-45-12;
      v0-45-12 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://airbytehq.github.io/helm-charts/airbyte-${version}.tgz";
    chart =
      { name ? defaults.name
      , namespace ? defaults.namespace
      , values ? [ ]
      , sets ? [ ]
      , version ? defaults.version
      , sha256 ? defaults.sha256
      , forceNamespace ? true
      , extraFlags ? [ hex.k8s.helm.constants.flags.create-namespace ]
      , sortYaml ? false
      }: hex.k8s.helm.build {
        inherit name namespace values sets version sha256 extraFlags forceNamespace sortYaml;
        url = chart_url version;
      };
  };
in
airbyte
