# [datadog](https://github.com/DataDog/helm-charts) provides helm charts to add logging and monitoring to your clusters. WARNING - extremely expensive!
{ hex, ... }:
let
  datadog = rec {
    defaults = {
      name = "datadog";
      namespace = "default";
      version = "3.59.2";
      sha256 = "0zdlvy0mql1klfjc5ails9yl164y09xdkjhi9v5bpsd5sxvidyrh";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v3-59-2;
      v3-59-2 = _v "3.59.2" "0zdlvy0mql1klfjc5ails9yl164y09xdkjhi9v5bpsd5sxvidyrh"; # 2024-03-21
      v3-58-1 = _v "3.58.1" "0y7qp6gvvvwkz9wgxkaijh1z1mh7cpw6rzpvxa4m6lv0bm8dy2ji"; # 2024-03-18
      v3-57-3 = _v "3.57.3" "0k21mjwfs9d6cdp5i4g9zp057v4646szh6qfkn59p946b7j090g2"; # 2024-02-23
      v3-56-0 = _v "3.56.0" "033ldkkyzk7gaxmmnkpcvm7qv9qmjj8ck3rvcpa2g4b70llmx22w"; # 2024-02-19
      v3-55-0 = _v "3.55.0" "1f5cnqc7643f6kajvhxgaxijf9nd5jc69sf6zw30lwivllav1gid"; # 2024-02-19
      v3-54-2 = _v "3.54.2" "0wrp8989c8ww765d60rax41shblv03lmxqq32k7yp8cc2zvlpk4f"; # 2024-02-13
      v3-54-1 = _v "3.54.1" "14fr4yclg0c2mmm4a9skkrg2vrzvqhmf3ldxgj6ix6irvnk10k05"; # 2024-02-13
      v3-53-3 = _v "3.53.3" "19m7jipwbqq2zmf462np7c5cs4536sw6njybx8b283vj4q51zhap"; # 2024-02-06
      v3-52-0 = _v "3.52.0" "0z72wh99m60c910pd322qd4md5fw98h40bq8bs3kmwjwqr4szzxg"; # 2024-01-18
      v3-51-2 = _v "3.51.2" "186gc8fql402pnwgb4ykwxs9fa93whkwrdlk98kcbcibwdghmh1j"; # 2024-01-16
      v3-45-0 = _v "3.45.0" "0z306k1v4zna4jp96yr9sh3aq9hqx5riapxymd3w8zq440n0w2h8";
      v3-1-9 = _v "3.1.9" "1wryym5v8pr70r3fs4i4y2mq8dihla07djnyis0q68l1j3m27mzs";
      v3-1-3 = _v "3.1.3" "004mr6jj046dqwfbd4zrs6qj8wqh9l8hwvrym9akdqr5fkilizzb";
    };
    chart_url = version: hex.k8s.helm.charts.url.github {
      inherit version;
      org = "DataDog";
      repo = "helm-charts";
      repoName = "datadog";
    };
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
datadog
