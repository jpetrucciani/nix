# This module contains an [elastic operator](https://github.com/elastic/cloud-on-k8s/)
_:
let
  elastic_url = "https://download.elastic.co/downloads/eck";
  elastic = {
    crds = rec {
      defaults = {
        name = "crds";
        namespace = "elastic-system";
        version = "2.9.0";
        sha256 = "0jfdwghdid73isfa80dpp6mpcksb1y55pny27sz513f5nx4blxc2";
      };
      version = rec {
        _v = v: s: chart.build { version = v; sha256 = s; };
        latest = v2-9-0;
        v2-9-0 = _v defaults.version defaults.sha256;
      };
      chart_url = version: "${elastic_url}/${version}/crds.yaml";
      chart = rec {
        build = { version ? defaults.version, sha256 ? defaults.sha256 }: ''
          ---
          ${setup {inherit version sha256;}}
        '';
        setup = { version, sha256 }: builtins.readFile (builtins.fetchurl {
          inherit sha256;
          url = chart_url version;
        });
      };
    };
    operator = rec {
      defaults = {
        name = "operator";
        namespace = "elastic-system";
        version = "2.9.0";
        sha256 = "1990b97sgxw8bj5rpg8rx2wghynbph1x2cy4akhdkqw26l174v87";
      };
      version = rec {
        _v = v: s: chart.build { version = v; sha256 = s; };
        latest = v2-9-0;
        v2-9-0 = _v defaults.version defaults.sha256;
      };
      chart_url = version: "${elastic_url}/${version}/operator.yaml";
      chart = rec {
        build = { version ? defaults.version, sha256 ? defaults.sha256 }: ''
          ---
          ${setup {inherit version sha256;}}
        '';
        setup = { version, sha256 }: builtins.readFile (builtins.fetchurl {
          inherit sha256;
          url = chart_url version;
        });
      };
    };
  };
in
elastic
