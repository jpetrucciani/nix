{ hex, ... }:
let
  repo_url = "https://helm.linkerd.io/stable";
  linkerd = {
    crds = rec {
      defaults = {
        name = "linkerd-crds";
        namespace = "linkerd";
        version = "1.6.1";
        sha256 = "1jnjy2p557ss5yp7nxgm1i9zyh981n0ijnblhw1a8i99sa327wv6";
      };
      version = rec {
        _v = v: s: args: chart (args // { version = v; sha256 = s; });
        latest = v1-6-1;
        v1-6-1 = _v defaults.version defaults.sha256;
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
    control-plane = rec {
      defaults = {
        name = "linkerd-control-plane";
        namespace = "linkerd";
        version = "1.12.5";
        sha256 = "10m2iqwp6x588w735hrpkjsvd5x6b1bdg847x5v1jzan92pxmv66";
      };
      version = rec {
        _v = v: s: args: chart (args // { version = v; sha256 = s; });
        latest = v1-12-5;
        v1-12-5 = _v defaults.version defaults.sha256;
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
linkerd
