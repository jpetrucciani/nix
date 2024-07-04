# This module contains helm charts under the [grafana](https://grafana.com/) observability umbrella. This includes things like [loki](https://github.com/grafana/loki), [mimir](https://github.com/grafana/mimir), and [oncall](https://github.com/grafana/oncall).
{ hex, ... }:
let
  _chart_url = { name, version, prefix ? "" }: "https://github.com/grafana/helm-charts/releases/download/${prefix}${name}-${version}/${name}-${version}.tgz";
  _chart = { defaults, prefix ? "" }:
    { name ? defaults.name
    , chart_name ? defaults.chart_name
    , namespace ? defaults.namespace
    , values ? [ ]
    , sets ? [ ]
    , version ? defaults.version
    , sha256 ? defaults.sha256
    , forceNamespace ? true
    , extraFlags ? [ hex.k8s.helm.constants.flags.create-namespace ]
    , preRender ? ""
    , postRender ? ""
    }: hex.k8s.helm.build {
      inherit name namespace sha256 values version forceNamespace sets extraFlags preRender postRender;
      url = _chart_url { inherit prefix version; name = chart_name; };
    };
  loki = rec {
    defaults = {
      name = "loki";
      chart_name = "loki";
      namespace = "loki";
      version = "6.0.0";
      sha256 = "08hy2fwr6rlqc0cf6g815fly45nmf1kv3ngfgmy4k2jyf5rd8z50";
    };
    chart = _chart { inherit defaults; prefix = "helm-"; };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v6-6-5;
      v6-6-5 = _v "6.6.5" "1mj0psnsswd04vaskxc6xqq0q0n5lir6j192ca1rgk3l8dlgyq9x"; # 2024-07-03
      v6-5-2 = _v "6.5.2" "00ydqpmgdhbclnian59nwlf4yjq4lqwmsfh0a7qm9267mxd37crc"; # 2024-05-10
      v6-4-2 = _v "6.4.2" "1yfk8m9yabyzv6lijymgf025069mbiswd4d55lldavzcqq96s5yk"; # 2024-04-30
      v6-3-4 = _v "6.3.4" "1130nycffid25rbnlgffsihhjiz75356iii0lmhkzrb8nlca8q7d"; # 2024-04-22
      v6-0-0 = _v "6.0.0" "08hy2fwr6rlqc0cf6g815fly45nmf1kv3ngfgmy4k2jyf5rd8z50"; # 2024-04-08
      v5-47-2 = _v "5.47.2" "0wax65hy9gc56gch0ypgm10a9qya5r6ygnnv3klna1a94nf32d4n"; # 2024-03-28
      v5-47-1 = _v "5.47.1" "171iwpniwc7q35vd5vgz9jzd8j24az4f3gsxgdlp1a4r5y5kxjm9"; # 2024-03-22
      v5-44-4 = _v "5.44.4" "124fms4hpqyr40a9jb5bvh48m5dvqi7m7xyq234c7d2jbqm0w201"; # 2024-03-18
      v5-43-7 = _v "5.43.7" "1n8mbv198kjx4drbvv6alh3l2vr86spvv3zik99ppajfpi8pv0rv"; # 2024-03-14
      v5-42-3 = _v "5.42.3" "0qkbivgpwbx7ffwh7szs725qhvla2bh1h66ja5zdnyry5wagcz8k"; # 2024-02-14
    };
  };
  mimir = rec {
    defaults = {
      name = "mimir";
      chart_name = "mimir-distributed";
      namespace = "mimir";
      version = "5.1.2";
      sha256 = "0frz4fs0za92flb81cgpxhjrkrsmypykz6ynn5j4z1vafqs4ckhq";
    };
    chart = _chart { inherit defaults; };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v5-3-0;
      v5-3-0 = _v "5.3.0" "1amv2qmpidsk6gl40pf7rfckmhvxqjzl7rc97b8p7h75wmwglhj4"; # 2024-04-10
      v5-2-3 = _v "5.2.3" "0d8snrg661fwm2p621h0wf8l8aygyc492xkdc5yxl89i33d29nbx"; # 2024-03-15
      v5-1-2 = _v "5.1.2" "0frz4fs0za92flb81cgpxhjrkrsmypykz6ynn5j4z1vafqs4ckhq";
    };
  };
  oncall = rec {
    defaults = {
      name = "oncall";
      chart_name = "oncall";
      namespace = "oncall";
    };
    chart = _chart { inherit defaults; };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v1-7-2;
      v1-7-2 = _v "1.7.2" "0xi4i4a0fklri71z2pia0ypj48nxw9nhvh7849yprjjmws35lrr6"; # 2024-06-20
      v1-7-1 = _v "1.7.1" "0fxklg48bvifbfss1xsahybzdz05hapyq2c2rfz91l8nxkrcqs3j"; # 2024-06-13
      v1-6-2 = _v "1.6.2" "1dzvv6wxrzxgv7ff25g1p5k2j3f3i1h4kvb35iwf8gw1lk4y3v12"; # 2024-06-05
      v1-5-5 = _v "1.5.5" "1jv6d8h7px45f0dab9ws92f4vjnyqq1b10k657rliks1kv93nqxs"; # 2024-06-03
      v1-4-7 = _v "1.4.7" "0a8ij66rcps0p3z8p69nl1y5742fh5a19slqfzl28kpzdikmx629"; # 2024-05-13
      v1-3-118 = _v "1.3.118" "0ywz3v2q9iy5z24rad3m9570hc3jwsfr1yzj0ba3m8fq4zyvb7k6"; # 2024-04-11
      v1-3-113 = _v "1.3.113" "0yqlsfhmcabppcczad6hdlaav2nxi9z9i4nn51h1rdh6w7g6xc2s"; # 2024-03-21
      v1-3-45 = _v "1.3.45" "1xrrryq5bvvbpxplpnwqn6yr0c1sp4k2idib5hybky8sczyfjjyn";
    };
  };
in
{ inherit loki mimir oncall; }
