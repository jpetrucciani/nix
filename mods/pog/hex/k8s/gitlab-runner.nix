# This module contains the helm chart for the [GitLab Kubernetes Executor](https://docs.gitlab.com/runner/executors/kubernetes.html).
{ hex, ... }:
let
  gitlab-runner = rec {
    defaults = {
      name = "gitlab-runner";
      namespace = "gitlab";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-67-0;
      v0-67-0 = _v "0.67.0" "0mjvx0y84lh6xn047gr3ccs588s3xwd8yqpwqy30nn6yxl7yl76r"; # 2024-07-18
      v0-66-0 = _v "0.66.0" "08fk6bz37sy8qdaqxbik4vpv0dwbrxggg6z1mp8mbs89zl206pnb"; # 2024-06-20
      v0-65-0 = _v "0.65.0" "1rpfnbx35ysvip2fr89hm4gnk4ficvpkz60rf2v56sq2dhchvl2f"; # 2024-05-23
      v0-64-1 = _v "0.64.1" "1xyxz4v3700kl14cjb37wm7wvcwdyk8qn2w5fisqz16x76hms6mh"; # 2024-05-03
      v0-63-0 = _v "0.63.0" "1nk77r2dcg3l1l2fpyp4dh79dvfmljfpch7n2v50ba1pmxca6qxj"; # 2024-03-22
      v0-62-0 = _v "0.62.0" "1h8zj211a6z1fmrs8ikf232fswyrf4x8zk90kdq84yga62brvbvr"; # 2024-02-15
      v0-61-3 = _v "0.61.3" "1qvv5zazaa7039jjkbh4rbi36dnx0s6zxvs73b211bz3jb6wrj5v"; # 2024-02-15
      v0-61-0 = _v "0.61.0" "0hc4b1v350hlnr0filwccza6bfyx0grabq8ldfgnc6chbl4m323d"; # 2024-01-19
      v0-60-1 = _v "0.60.1" "0r224arp4zi76d7sbybg9rdnwzwkl6ayq8iwb3v2zk8w83p0y33y"; # 2024-01-19
      v0-60-0 = _v "0.60.0" "1k0gdg2mvm98s8msrsnr0aqsblhigbr7y6fg263yd6mmg8yzxlcp"; # 2023-12-21
      v0-59-3 = _v "0.59.3" "11i6p6bp2ysxyv6v22lv7z8d6nc8nlibvbvvrqxnivrp7wjl4yah"; # 2023-12-21
    };
    chart_url = version: "https://gitlab-charts.s3.amazonaws.com/gitlab-runner-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
gitlab-runner
