{ hex, ... }:
let
  sentry = rec {
    defaults = {
      name = "sentry";
      namespace = "sentry";
      version = "20.4.0";
      sha256 = "0r3lz1fqb7x6bcgnja8mhk7i0f3747a1g9ymx9ly2j05zzyp81jf";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v20-4-0;
      v20-4-0 = _v defaults.version defaults.sha256;
      v20-3-2 = _v "20.3.2" "1xwg8s5zxm24x1rspjgk9zwgxv8kkkywf2hl6qj149fvxn0k758d";
      v20-3-0 = _v "20.3.0" "0f09rlq6m98n9jjlk42rrkhyf39jh4ppz5rmx2ngx5nipkvrjkj9";
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
      , postRender ? ""
      }: hex.k8s.helm.build {
        inherit name namespace values sets version sha256 extraFlags forceNamespace sortYaml postRender;
        url = chart_url version;
      };
  };
in
sentry
