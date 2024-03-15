# various cluster addons [out of date]
{ hex, pkgs, ... }:
let
  inherit (hex) toYAML;

  addons = {
    nfs-subdir-external-provisioner = rec {
      defaults = {
        name = "nfs-subdir-external-provisioner";
        namespace = "default";
        version = "4.0.17";
        sha256 = "0qz86d8fbc23n385rkxlyz6rqhbh2ackd8zl020dp7m51102img0";
      };
      version = rec {
        _v = hex.k8s._.version chart;
        latest = v4-0-17;
        v4-0-17 = _v "4.0.17" "0qz86d8fbc23n385rkxlyz6rqhbh2ackd8zl020dp7m51102img0";
      };
      chart_url = version: "https://github.com/kubernetes-sigs/${defaults.name}/releases/download/${defaults.name}-${version}/${defaults.name}-${version}.tgz";
      chart =
        { server
        , mountPath ? "/export/"
        , name ? defaults.name
        , namespace ? defaults.namespace
        , values ? [ ]
        , sets ? [ ]
        , version ? defaults.version
        , sha256 ? defaults.sha256
        , forceNamespace ? true
        , extraFlags ? [ ]
        , sortYaml ? false
        , extraValues ? { }
        }:
        let
          _values = {
            nfs.server = server;
            nfs.path = mountPath;
          };
          values_file = pkgs.writeTextFile {
            name = "nfs-values.yaml";
            text = toYAML (_values // extraValues);
          };
        in
        hex.k8s.helm.build {
          inherit name namespace sets version sha256 extraFlags forceNamespace sortYaml;
          url = chart_url version;
          values = [ values_file ] ++ values;
        };
    };
  };
in
addons
