{ hex, pkgs, ... }:
let
  gitlab-runner = rec {
    defaults = {
      name = "gitlab-runner";
      namespace = "gitlab";
      version = "0.49.0";
      sha256 = "1jf9lrd3d2akxzmk2ss0crwr2dkld6adxigmi9k1zmh25kp2qr6y";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v0-49-0;
      v0-49-0 = _v "0.49.0" "1jf9lrd3d2akxzmk2ss0crwr2dkld6adxigmi9k1zmh25kp2qr6y";
      v0-48-2 = _v "0.48.2" "1q56b3vp8rc30ac74z443nq2z482jdacz4x49azpa8h7gza79zxq";
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
