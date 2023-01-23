{ hex, ... }:
let
  authentik = rec {
    defaults = {
      name = "authentik";
      namespace = "default";
      version = "2023.1.1";
      sha256 = "1952ybfp2v0nd3j35p1k2jkdaiim5giwfhbdz1mhjwa7cj0c5vnd";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v2023-1-1;
      v2023-1-1 = _v defaults.version defaults.sha256;
      v2022-12-4 = _v "2022.12.4" "12s7qd09sz3mwxi7zg4406lgyy06qbg0l9ky2si8lcnsbmxj0g6f";
      v2022-12-2 = _v "2022.12.2" "0klhs31vpis0g9nnfhhh76lcd9y09g8b095cdc51kxgb2cv67r0d";
      v2022-12-1 = _v "2022.12.1" "0wyjc573d8f4hjzk17bwzbb4l0rlg13d1iz9j34zzhy2shifjs1v";
      v2022-12-0 = _v "2022.12.0" "1j73575vizrhvb4a9dk81asvdrnvf3901syln9nrmq6y81pdbqqf";
      v2022-11-4 = _v "2022.11.4" "19r6pw48mdd9l9b0k5slqnhqnj4ybv997n5nzkamnv8c0x09jka8";
      v2022-11-3 = _v "2022.11.3" "0ligh6dziyji2llz0b60s0hicighr0p9k42ylgaw4cvkxg4fpyk1";
      v2022-10-0 = _v "2022.10.0" "0k6m6zi0pjihl1wqzrm7akymzswlqbg9qpf9f6fz3wicj63cj6bv";
      v2022-9-0 = _v "2022.9.0" "1r8hnacfl70ih5d3vqp6zk2c94gffqimmj4cw5g4lbri65gzgl1l";
      v2022-7-3 = _v "2022.7.3" "05vv6wjyf1vkfy2qmp4yshb4pxyg246fkpc6v6gp3b5h5y55ds30";
    };
    chart_url = version: "https://github.com/goauthentik/helm/releases/download/authentik-${version}/authentik-${version}.tgz";
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
authentik
