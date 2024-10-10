# [open-webui](https://github.com/open-webui/open-webui) is a user-friendly AI interface
{ hex, ... }:
let
  name = "open-webui";

  # example values file here: https://github.com/open-webui/helm-charts/blob/main/charts/open-webui/values.yaml
  open-webui = rec {
    defaults = {
      inherit name;
      namespace = "default";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v3-3-2;
      v3-3-2 = _v "3.3.2" "0p7yg4lqips9krvcbzflva9dldqbnf71v3dz64zl744l928635mp"; # 2024-10-08
    };
    chart_url = version: "https://github.com/open-webui/helm-charts/releases/download/${name}-${version}/${name}-${version}.tgz";
    chart = hex.k8s._.chart {
      inherit defaults chart_url;
    };
  };
in
open-webui
