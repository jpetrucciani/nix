# [pulp](https://github.com/pulp/pulp-operator) is a platform for managing RPMs and other software artifacts
{ hex, ... }:
let
  name = "pulp";
  pulp = rec {
    defaults = {
      inherit name;
      namespace = name;
      version = "0.1.0";
      sha256 = "1jpcnh9m7709v733mhddvccn35mgbdbsrq0yjxnhh6rjdb36yk92";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-1-0;
      v0-1-0 = _v "0.1.0" "1jpcnh9m7709v733mhddvccn35mgbdbsrq0yjxnhh6rjdb36yk92"; # 2024-04-04
    };
    chart_url = version: "https://github.com/${name}/pulp-k8s-resources/releases/download/1.0.0-beta.4/${name}-operator-${version}.tgz";
    chart = hex.k8s._.chart { inherit defaults chart_url; };
  };
in
pulp
