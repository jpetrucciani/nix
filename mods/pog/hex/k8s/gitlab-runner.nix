{ hex, ... }:
let
  gitlab-runner = rec {
    defaults = {
      name = "gitlab-runner";
      namespace = "gitlab";
      version = "0.56.1";
      sha256 = "1pvyckvx9345z5lawgnaaa4w6dj6j65f2l1m6dycvb22sbkghcqc";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v0-56-1;
      v0-56-1 = _v "0.56.1" "1pvyckvx9345z5lawgnaaa4w6dj6j65f2l1m6dycvb22sbkghcqc";
      v0-55-0 = _v "0.55.0" "18nfn57b6hwd3px43qjpnhf4hz9a13266z32wpi7vv3drmhfvmb0";
      v0-54-0 = _v "0.54.0" "0pmikfklgw68ryngkyjj2swcr13fjjq6iaxf4gvq5pvl9w13q9dm";
      v0-53-2 = _v "0.53.2" "0nr2ikp5xgrd5hi4vhsfbfm91lx66yr61brh4rijk4v6ci4lqk4w";
      v0-52-1 = _v "0.52.1" "0wwn77rj47g2scs2byrmnlk68vhmmq00721ai1mzrzx0i5smd307";
      v0-51-1 = _v "0.51.1" "1si0w6nj1hacanq8hjjjbfgqp9c7wal1mic08m7n4mszg8fl9n05";
      v0-50-1 = _v "0.50.1" "1i80asaxdpm2pdvya924lix1qwxq9zn89vr19a6jw42fyr74rvyf";
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
        inherit name namespace sha256 values version forceNamespace sets extraFlags;
        url = chart_url version;
      };
  };
in
gitlab-runner
