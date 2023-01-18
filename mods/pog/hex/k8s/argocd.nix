{ hex, ... }:
let
  argocd = rec {
    defaults = {
      name = "argocd";
      namespace = "argocd";
      version = "4.10.6";
      sha256 = "15bmai7k9bih5v3l29s5pvzgdqcbd4ff9302vz9xrgkdbbwm8bfp";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      v4-10-6 = _v defaults.version defaults.sha256;
      latest = v4-10-6;
    };
    chart_url = version: "https://github.com/argoproj/argo-helm/releases/download/argo-cd-${version}/argo-cd-${version}.tgz";
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
argocd
