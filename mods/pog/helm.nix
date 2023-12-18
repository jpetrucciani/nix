final: prev:
let
  grafana_chart = { name, prefix ? "", filter_out ? "" }: _chart_scan {
    inherit name filter_out;
    base_url = "https://grafana.github.io/helm-charts";
    chart_url = "https://github.com/grafana/helm-charts/releases/download/${prefix}${name}-{1}/${name}-{1}.tgz";
  };
  _chart_scan =
    { name
    , exe_name ? name
    , base_url
    , index_url ? "${base_url}/index.yaml"
    , chart_url ? "${base_url}/${name}-{1}.tgz"
    , chart_name ? name
    , last ? 10
    , filter_out ? ""
    }:
    let
      mktemp = "${final.coreutils}/bin/mktemp";
      jq = final.lib.getExe final.jaq;
      yq = "${final.yq-go}/bin/yq";
      parallel = "${final.parallel}/bin/parallel --will-cite --keep-order -j0 --colsep ' '";
      _filter = if (builtins.stringLength filter_out) > 0 then ''${final.gnused}/bin/sed -E -e '/${filter_out}/,+1d' | '' else "";
    in
    final.pog {
      name = "chart_scan_${exe_name}";
      description = "a quick and easy way to get the latest x releases of the '${exe_name}' chart!";
      script = ''
        # temp files
        temp_resp="$(${mktemp} --suffix=.yaml)"
        temp_json="$(${mktemp} --suffix=.json)"
        temp_csv="$(${mktemp} --suffix=.csv)"

        # grab index for this chart
        ${final.curl}/bin/curl -L -s '${index_url}' >"$temp_resp"
        
        debug "pulled chart data to $temp_resp"

        <"$temp_resp" ${yq} '.[].${chart_name}.[] | [{"version": .version, "date": .created}]' | ${_filter}
            ${final.coreutils}/bin/head -n ${toString (last * 2)} |
            ${yq} -o=json >"$temp_json"

        debug "parsed json into $temp_json"

        # form csv, hash in parallel
        echo "version,date,sha256" >>"$temp_csv"
        ${jq} -r '.[] | (.version + " " + .date)' <"$temp_json" |
            ${parallel} 'echo -n "{1},{=2 uq(); =},"; nix-prefetch-url --unpack "${chart_url}" 2>/dev/null' >>"$temp_csv"

        debug "formed json into csv at $temp_csv"

        # format as json
        ${yq} "$temp_csv" -p=csv -o=json
      '';
    };
in
rec {
  inherit _chart_scan;

  chart_scan_argo-cd = _chart_scan {
    name = "argo-cd";
    base_url = "https://argoproj.github.io/argo-helm";
    chart_url = "https://github.com/argoproj/argo-helm/releases/download/argo-cd-{1}/argo-cd-{1}.tgz";
    last = 100;
  };

  chart_scan_authentik = _chart_scan {
    name = "authentik";
    base_url = "https://charts.goauthentik.io";
    chart_url = "https://github.com/goauthentik/helm/releases/download/authentik-{1}/authentik-{1}.tgz";
  };

  chart_scan_datadog = _chart_scan {
    name = "datadog";
    base_url = "https://helm.datadoghq.com";
    chart_url = "https://github.com/DataDog/helm-charts/releases/download/datadog-{1}/datadog-{1}.tgz";
  };

  chart_scan_external-secrets = _chart_scan {
    name = "external-secrets";
    base_url = "https://charts.external-secrets.io";
    chart_url = "https://github.com/external-secrets/external-secrets/releases/download/helm-chart-{1}/external-secrets-{1}.tgz";
  };

  chart_scan_gitlab-runner = _chart_scan {
    name = "gitlab-runner";
    base_url = "https://gitlab-charts.s3.amazonaws.com";
  };

  chart_scan_traefik = let base = "https://traefik.github.io/charts"; in
    _chart_scan {
      name = "traefik";
      base_url = base;
      chart_url = "${base}/traefik/traefik-{1}.tgz";
    };

  chart_scan_stackstorm = _chart_scan {
    name = "stackstorm";
    chart_name = "stackstorm-ha";
    base_url = "https://helm.stackstorm.com";
  };

  chart_scan_signoz = _chart_scan {
    name = "signoz";
    base_url = "https://charts.signoz.io";
    chart_url = "https://github.com/SigNoz/charts/releases/download/signoz-{1}/signoz-{1}.tgz";
  };

  chart_scan_infisical = _chart_scan {
    name = "infisical";
    base_url = "https://dl.cloudsmith.io/public/infisical/helm-charts/helm/charts";
  };

  chart_scan_nfs = let chart = "nfs-subdir-external-provisioner"; in
    _chart_scan {
      name = "nfs";
      chart_name = chart;
      base_url = "https://kubernetes-sigs.github.io/${chart}";
      chart_url = "https://github.com/kubernetes-sigs/${chart}/releases/download/${chart}-{1}/${chart}-{1}.tgz";
    };

  chart_scan_robusta = _chart_scan {
    name = "robusta";
    base_url = "https://robusta-charts.storage.googleapis.com";
  };

  chart_scan_airbyte = _chart_scan {
    name = "airbyte";
    base_url = "https://airbytehq.github.io/helm-charts";
  };

  chart_scan_sentry = _chart_scan {
    name = "sentry";
    base_url = "https://sentry-kubernetes.github.io/charts";
  };

  chart_scan_linkerd-crds = _chart_scan {
    name = "linkerd-crds";
    base_url = "https://helm.linkerd.io/stable";
  };

  chart_scan_linkerd-control-plane = _chart_scan {
    name = "linkerd-control-plane";
    base_url = "https://helm.linkerd.io/stable";
  };

  chart_scan_postgres-operator = _chart_scan {
    name = "postgres-operator";
    base_url = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator";
  };

  chart_scan_postgres-operator-ui = _chart_scan {
    name = "postgres-operator-ui";
    base_url = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui";
  };

  chart_scan_jupyterhub = _chart_scan {
    name = "jupyterhub";
    base_url = "https://hub.jupyter.org/helm-chart";
    filter_out = "alpha|beta|dev";
  };

  chart_scan_kube-prometheus-stack = _chart_scan rec {
    name = "kube-prometheus-stack";
    base_url = "https://prometheus-community.github.io/helm-charts";
    chart_url = "https://github.com/prometheus-community/helm-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
  };

  chart_scan_loki = grafana_chart { name = "loki"; prefix = "helm-"; };
  chart_scan_mimir = grafana_chart { name = "mimir-distributed"; filter_out = "weekly|rc"; };
  chart_scan_oncall = grafana_chart { name = "oncall"; };

  chart_scan_terrakube = _chart_scan rec {
    name = "terrakube";
    base_url = "https://azbuilder.github.io/terrakube-helm-chart";
    chart_url = "https://github.com/AzBuilder/terrakube-helm-chart/releases/download/${name}-{1}/${name}-{1}.tgz";
  };

  chart_scan_otf = _chart_scan rec {
    name = "otf";
    base_url = "https://leg100.github.io/otf-charts";
    chart_url = "https://github.com/leg100/otf-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
  };

  chart_scan_mongo-operator = _chart_scan rec {
    name = "community-operator";
    exe_name = "mongo-operator";
    base_url = "https://mongodb.github.io/helm-charts";
    chart_url = "https://github.com/mongodb/helm-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
  };

  chart_scan_redis-operator = _chart_scan rec {
    name = "redis-operator";
    base_url = "https://spotahome.github.io/redis-operator";
    chart_url = "https://github.com/spotahome/${name}/releases/download/Chart-{1}/${name}-{1}.tgz";
  };

  helm_pog_scripts = [
    chart_scan_argo-cd
    chart_scan_authentik
    chart_scan_datadog
    chart_scan_external-secrets
    chart_scan_gitlab-runner
    chart_scan_infisical
    chart_scan_jupyterhub
    chart_scan_kube-prometheus-stack
    chart_scan_linkerd-crds
    chart_scan_linkerd-control-plane
    chart_scan_loki
    chart_scan_mimir
    chart_scan_mongo-operator
    chart_scan_nfs
    chart_scan_oncall
    chart_scan_otf
    chart_scan_postgres-operator
    chart_scan_postgres-operator-ui
    chart_scan_redis-operator
    chart_scan_robusta
    chart_scan_sentry
    chart_scan_signoz
    chart_scan_stackstorm
    chart_scan_terrakube
    chart_scan_traefik
  ];
}
