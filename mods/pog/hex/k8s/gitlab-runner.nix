{ hex, pkgs, ... }:
let
  inherit (hex) toYAML;

  gitlab-runner = rec {
    defaults = {
      name = "gitlab-runner";
      namespace = "gitlab";
      version = "0.47.1";
      sha256 = "0d90ffhmqy6n0kxb07dyxyzhdd8k8l510zvm30kpj1l0nzf0b9xb";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v0-47-1;
      v0-47-1 = _v "0.47.1" "0d90ffhmqy6n0kxb07dyxyzhdd8k8l510zvm30kpj1l0nzf0b9xb";
      v0-46-1 = _v "0.46.1" "065hhf1z5kgv9vidyq0zld19qm3rgqhppkzlyy0nsyz4vl1cik56";
      v0-45-1 = _v "0.45.1" "0pzgpa29f7lxcsf3jd11jib6fb65f5yj76jn2np8a2nlip58v3lz";
      v0-44-3 = _v "0.44.3" "1mgqswh98bg13a0ng1m2wh26vrkcmpk7vxfi8bjknb58z1ndncvq";
    };
    chart_url = version: "https://gitlab-charts.s3.amazonaws.com/gitlab-runner-${version}.tgz";
    chart =
      { name ? defaults.name
      , namespace ? defaults.namespace
      , values ? [ ]
      , sets ? [ ]
      , version ? defaults.version
      , sha256 ? defaults.sha256
      , forceNamespace ? true
      , extraFlags ? [ hex.k8s.helm.constants.flags.create-namespace ]
      }: hex.k8s.helm.build {
        inherit name namespace sha256 values version forceNamespace sets;
        url = chart_url version;
      };
  };
in
gitlab-runner
