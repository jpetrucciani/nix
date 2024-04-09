# [postgres-operator](https://github.com/zalando/postgres-operator) creates and manages PostgreSQL clusters running in Kubernetes
{ hex, ... }:
let
  repo_url = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator";
  postgres = {
    operator = rec {
      defaults = {
        name = "postgres-operator";
        namespace = "default";
        version = "1.11.0";
        sha256 = "0ypjzvikjq085yvh7m6c74x9dk8zark0gmdj2f34lph9hm78al1x";
      };
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v1-11-0;
        v1-11-0 = _v "1.11.0" "0ypjzvikjq085yvh7m6c74x9dk8zark0gmdj2f34lph9hm78al1x"; # 2024-03-27
        v1-10-1 = _v "1.10.1" "04wpirx90j7jvnkv1pr99pyhn3jhp3mcp8529qhkfmpjjl76w0kk";
        v1-10-0 = _v "1.10.0" "1hjv747i0awgcgq095gjilk5fmy8ibcc86p0mlz8imygfd6g792z";
      };
      chart_url = version: "${repo_url}/${defaults.name}-${version}.tgz";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
    ui = rec {
      defaults = {
        name = "postgres-operator-ui";
        namespace = "default";
        version = "1.11.0";
        sha256 = "035ri6b4mjvdlhrwl8fpyw173bf9ny9qla5fvql9c4yj7gw4j2q2";
      };
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v1-10-1;
        v1-11-0 = _v "1.11.0" "035ri6b4mjvdlhrwl8fpyw173bf9ny9qla5fvql9c4yj7gw4j2q2"; # 2024-03-14
        v1-10-1 = _v "1.10.1" "04sfk6habw9w1laci5rynzhxqvgpkxmadcxzabk98v03dds9gjl8";
        v1-10-0 = _v "1.10.0" "18x16v75rzl7d2rrl455ilr3n8sz83n0n5vwkpl9sz7jnva66g4f";
      };
      chart_url = version: "${repo_url}-ui/${defaults.name}-${version}.tgz";
      chart = hex.k8s._.chart { inherit defaults chart_url; };
    };
  };
in
postgres
