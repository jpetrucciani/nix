# [k8s gateway api](https://github.com/kubernetes-sigs/gateway-api) CRDs
_:
let
  inherit (builtins) fetchurl readFile;
  gateway = rec {
    defaults = {
      name = "gateway-api";
      version = "1.0.0";
      sha256 = "0ajdhgqw3ppvgwir3aw3l1vyrk8rqf2kzyzpfis5i83jbh4y3r13";
    };
    version = rec {
      _v = v: s: chart.build { version = v; sha256 = s; };
      latest = v1-0-0;
      v1-0-0 = _v defaults.version defaults.sha256;
    };
    spec_url = version: "https://github.com/kubernetes-sigs/gateway-api/releases/download/v${version}/standard-install.yaml";
    chart = rec {
      build = { version ? defaults.version, sha256 ? defaults.sha256 }: ''
        ---
        ${setup {inherit version sha256;}}
      '';
      setup = { version, sha256 }: readFile (fetchurl {
        inherit sha256;
        url = spec_url version;
      });
    };
  };
in
gateway
