{ hex, ... }:
let
  gitlab-runner = rec {
    defaults = {
      name = "gitlab-runner";
      namespace = "gitlab";
      version = "0.62.0";
      sha256 = "1h8zj211a6z1fmrs8ikf232fswyrf4x8zk90kdq84yga62brvbvr";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-62-0;
      v0-62-0 = _v "0.62.0" "1h8zj211a6z1fmrs8ikf232fswyrf4x8zk90kdq84yga62brvbvr"; # 2024-02-15
      v0-61-3 = _v "0.61.3" "1qvv5zazaa7039jjkbh4rbi36dnx0s6zxvs73b211bz3jb6wrj5v"; # 2024-02-15
      v0-61-0 = _v "0.61.0" "0hc4b1v350hlnr0filwccza6bfyx0grabq8ldfgnc6chbl4m323d"; # 2024-01-19
      v0-60-1 = _v "0.60.1" "0r224arp4zi76d7sbybg9rdnwzwkl6ayq8iwb3v2zk8w83p0y33y"; # 2024-01-19
      v0-60-0 = _v "0.60.0" "1k0gdg2mvm98s8msrsnr0aqsblhigbr7y6fg263yd6mmg8yzxlcp"; # 2023-12-21
      v0-59-3 = _v "0.59.3" "11i6p6bp2ysxyv6v22lv7z8d6nc8nlibvbvvrqxnivrp7wjl4yah"; # 2023-12-21
      v0-58-2 = _v "0.58.2" "0h9nzls8g9gbh371y2z41lpc4v2yyd515dccqbrczd2dlziqzsm8";
      v0-57-2 = _v "0.57.2" "0wy2l0cpqj9nmzfk6gy5yw55dgkc03lq5mwzkw8g0f1yz43p4f3g";
      v0-56-1 = _v "0.56.1" "1pvyckvx9345z5lawgnaaa4w6dj6j65f2l1m6dycvb22sbkghcqc";
      v0-55-0 = _v "0.55.0" "18nfn57b6hwd3px43qjpnhf4hz9a13266z32wpi7vv3drmhfvmb0";
      v0-54-0 = _v "0.54.0" "0pmikfklgw68ryngkyjj2swcr13fjjq6iaxf4gvq5pvl9w13q9dm";
      v0-53-2 = _v "0.53.2" "0nr2ikp5xgrd5hi4vhsfbfm91lx66yr61brh4rijk4v6ci4lqk4w";
      v0-52-1 = _v "0.52.1" "0wwn77rj47g2scs2byrmnlk68vhmmq00721ai1mzrzx0i5smd307";
      v0-51-1 = _v "0.51.1" "1si0w6nj1hacanq8hjjjbfgqp9c7wal1mic08m7n4mszg8fl9n05";
      v0-50-1 = _v "0.50.1" "1i80asaxdpm2pdvya924lix1qwxq9zn89vr19a6jw42fyr74rvyf";
    };
    chart_url = version: "https://gitlab-charts.s3.amazonaws.com/gitlab-runner-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
gitlab-runner
