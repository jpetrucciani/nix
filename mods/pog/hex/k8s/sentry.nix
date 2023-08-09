{ hex, ... }:
let
  sentry = rec {
    defaults = {
      name = "sentry";
      namespace = "sentry";
      version = "20.3.0";
      sha256 = "0f09rlq6m98n9jjlk42rrkhyf39jh4ppz5rmx2ngx5nipkvrjkj9";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v20-3-0;
      v20-3-0 = _v defaults.version defaults.sha256;
    };
    chart_url = version: "https://sentry-kubernetes.github.io/charts/sentry-${version}.tgz";
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
sentry
