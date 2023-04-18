{ hex, ... }:
let
  authentik = rec {
    defaults = {
      name = "authentik";
      namespace = "default";
      version = "2023.4.1";
      sha256 = "0m02dvvrhfx02kk8y2zdjgqyra0q600477bp30n5zcv0r4kxqphz";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v2023-4-1;
      v2023-4-1 = _v defaults.version defaults.sha256;
      v2023-3-1 = _v "2023.3.1" "0jgh96b28xfn37bg16n4ypw5m7i4x9b7y2f26f47nsf5vvcm0d75";
      v2023-2-4 = _v "2023.2.4" "03li78dnzbdlaqbinqkjqfk2fzk8m5xy0jq2n5b573r5ann51dpd";
      v2023-1-2 = _v "2023.1.2" "1vym8san70qcqxbfphvv3f8q09f1yf67pf9vx2zc3yl0dziv76qj";
      v2022-12-4 = _v "2022.12.4" "12s7qd09sz3mwxi7zg4406lgyy06qbg0l9ky2si8lcnsbmxj0g6f";
      v2022-11-4 = _v "2022.11.4" "19r6pw48mdd9l9b0k5slqnhqnj4ybv997n5nzkamnv8c0x09jka8";
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
