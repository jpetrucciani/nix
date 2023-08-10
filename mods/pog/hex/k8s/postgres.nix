{ hex, ... }:
let
  repo_url = "https://opensource.zalando.com/postgres-operator/charts";
  postgres = {
    operator = rec {
      defaults = {
        name = "postgres-operator";
        namespace = "default";
        version = "1.10.0";
        sha256 = "1hjv747i0awgcgq095gjilk5fmy8ibcc86p0mlz8imygfd6g792z";
      };
      version = rec {
        _v = v: s: args: chart (args // { version = v; sha256 = s; });
        latest = v1-10-0;
        v1-10-0 = _v defaults.version defaults.sha256;
      };
      chart_url = version: "${repo_url}/${defaults.name}-${version}.tgz";
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
    ui = rec {
      defaults = {
        name = "postgres-operator-ui";
        namespace = "default";
        version = "1.10.0";
        sha256 = "18x16v75rzl7d2rrl455ilr3n8sz83n0n5vwkpl9sz7jnva66g4f";
      };
      version = rec {
        _v = v: s: args: chart (args // { version = v; sha256 = s; });
        latest = v1-10-0;
        v1-10-0 = _v defaults.version defaults.sha256;
      };
      chart_url = version: "${repo_url}/${defaults.name}-${version}.tgz";
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
  };
in
postgres
