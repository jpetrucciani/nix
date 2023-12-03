{ hex, ... }:
let
  repo_url = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator";
  postgres = {
    operator = rec {
      defaults = {
        name = "postgres-operator";
        namespace = "default";
        version = "1.10.1";
        sha256 = "04wpirx90j7jvnkv1pr99pyhn3jhp3mcp8529qhkfmpjjl76w0kk";
      };
      version = rec {
        _v = v: s: args: chart (args // { version = v; sha256 = s; });
        latest = v1-10-1;
        v1-10-1 = _v defaults.version defaults.sha256;
        v1-10-0 = _v "1.10.0" "1hjv747i0awgcgq095gjilk5fmy8ibcc86p0mlz8imygfd6g792z";
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
        , postRender ? ""
        }: hex.k8s.helm.build {
          inherit name namespace values sets version sha256 extraFlags forceNamespace sortYaml postRender;
          url = chart_url version;
        };
    };
    ui = rec {
      defaults = {
        name = "postgres-operator-ui";
        namespace = "default";
        version = "1.10.1";
        sha256 = "04sfk6habw9w1laci5rynzhxqvgpkxmadcxzabk98v03dds9gjl8";
      };
      version = rec {
        _v = v: s: args: chart (args // { version = v; sha256 = s; });
        latest = v1-10-1;
        v1-10-1 = _v defaults.version defaults.sha256;
        v1-10-0 = _v "1.10.0" "18x16v75rzl7d2rrl455ilr3n8sz83n0n5vwkpl9sz7jnva66g4f";
      };
      chart_url = version: "${repo_url}-ui/${defaults.name}-${version}.tgz";
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
  };
in
postgres
