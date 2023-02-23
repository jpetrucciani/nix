{ hex, pkgs, ... }:
let
  gitlab-runner = rec {
    defaults = {
      name = "gitlab-runner";
      namespace = "gitlab";
      version = "0.50.1";
      sha256 = "1i80asaxdpm2pdvya924lix1qwxq9zn89vr19a6jw42fyr74rvyf";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v0-50-1;
      v0-50-1 = _v "0.50.1" "1i80asaxdpm2pdvya924lix1qwxq9zn89vr19a6jw42fyr74rvyf";
      v0-49-2 = _v "0.49.3" "122ybk10bfmk613ira789zhmqqpcq8pba6nm2pc1ld5sadylf8d3";
      v0-48-2 = _v "0.48.3" "1n82lknri9amlj8h1z12kzc004zrfcwif2ch1xrqa7rxzgzrhr4x";
      v0-47-3 = _v "0.47.3" "1cinfqyizbdi5na0av4vdgax4j3czaf4rywxf4npryhw6z5dlybj";
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
