# This module provides some tools for analyzing helm repos and charts!
final: prev:
let
  coroot_chart = { name, prefix ? "", filter_out ? "", last ? 20 }: _chart_scan {
    inherit name filter_out last;
    base_url = "https://coroot.github.io/helm-charts";
    chart_url = "https://github.com/coroot/helm-charts/releases/download/${prefix}${name}-{1}/${name}-{1}.tgz";
  };
  grafana_chart = { name, prefix ? "", filter_out ? "", last ? 20 }: _chart_scan {
    inherit name filter_out last;
    base_url = "https://grafana.github.io/helm-charts";
    chart_url = "https://github.com/grafana/helm-charts/releases/download/${prefix}${name}-{1}/${name}-{1}.tgz";
  };
  prometheus_chart = { name, prefix ? "", filter_out ? "", last ? 40 }: _chart_scan {
    inherit name filter_out last;
    base_url = "https://prometheus-community.github.io/helm-charts";
    chart_url = "https://github.com/prometheus-community/helm-charts/releases/download/${prefix}${name}-{1}/${name}-{1}.tgz";
  };
  _chart_scan =
    { name
    , exe_name ? name
    , base_url
    , index_url ? "${base_url}/index.yaml"
    , chart_url ? "${base_url}/${name}-{1}.tgz"
    , chart_name ? name
    , last ? 20
    , filter_out ? ""
    }:
    let
      jq = final.lib.getExe final.jaq;
      yq = "${final.yq-go}/bin/yq";
      parallel = "${final.parallel}/bin/parallel --will-cite --keep-order -j0 --colsep ' '";
      _filter = if (builtins.stringLength filter_out) > 0 then ''${final.gnused}/bin/sed -E -e '/${filter_out}/,+1d' | '' else "";
      v_format = final.writeTextFile {
        name = "v_format.py";
        text = ''
          import json
          import sys
          from datetime import datetime

          data = json.load(open(sys.argv[1]))
          def _format(entry: dict[str, str]) -> str:
              version = entry["version"]
              sha256 = entry["sha256"]
              date = datetime.fromisoformat(entry["date"]).strftime("%Y-%m-%d")
              attr = version.replace(".", "-").strip().split("+")[0]
              prefix = "v" if attr[0] != "v" else ""
              return f'{prefix}{attr} = _v "{version}" "{sha256}"; # {date}'

          print("\n".join(_format(x) for x in data))
        '';
      };
    in
    final.pog {
      name = "chart_scan_${exe_name}";
      description = "a quick and easy way to get the latest x releases of the '${exe_name}' chart!";
      flags = [
        {
          name = "last";
          description = "the number of chart versions to load and hash";
          default = toString last;
        }
        {
          name = "vformat";
          description = "print in v format for updating the hex source";
          bool = true;
        }
      ];
      shortDefaultFlags = false;
      script = helpers: with helpers; ''
        # temp files
        temp_resp=${tmp.yaml}
        temp_json=${tmp.json}
        temp_csv=${tmp.csv}
        final_json=${tmp.json}
        count="$((last*2))"

        # grab index for this chart
        ${final.curl}/bin/curl -L -s '${index_url}' >"$temp_resp"
        
        debug "pulled chart data to $temp_resp"

        <"$temp_resp" ${yq} '.[].${chart_name}.[] | [{"version": .version, "date": .created}]' | ${_filter}
            ${final.coreutils}/bin/head -n "$count" |
            ${yq} -o=json >"$temp_json"

        debug "parsed json into $temp_json"

        # form csv, hash in parallel
        echo "version,date,sha256" >>"$temp_csv"
        # shellcheck disable=SC2016
        ${jq} -r '.[] | (.version + " " + .date)' <"$temp_json" |
            ${parallel} --rpl '{strip_plus} s/(.*)\+.*/\1/;' --rpl '{ymd} s/(.*)T.*/\1/;' 'echo -n "{1},{=2 uq(); =},"; nix-prefetch-url --unpack "${chart_url}" 2>/dev/null' >>"$temp_csv"

        debug "formed json into csv at $temp_csv"

        # format as json
        ${yq} "$temp_csv" -p=csv -o=json >"$final_json"

        if ${flag "vformat"}; then
          ${final.python3}/bin/python ${v_format} "$final_json"
        else
          ${yq} "$final_json"
        fi
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

  # chart_scan_datadog = _chart_scan {
  #   name = "datadog";
  #   base_url = "https://helm.datadoghq.com";
  #   chart_url = "https://github.com/DataDog/helm-charts/releases/download/datadog-{1}/datadog-{1}.tgz";
  # };

  chart_scan_fleet = _chart_scan {
    name = "fleet";
    base_url = "https://fleetdm.github.io/fleet/charts";
    chart_url = "https://fleetdm.github.io/fleet/charts/fleet-{1}.tgz";
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

  chart_scan_langflow-ide =
    let
      base_url = "https://langflow-ai.github.io/langflow-helm-charts";
      name = "langflow-ide";
    in
    _chart_scan {
      inherit name base_url;
      chart_url = "https://github.com/langflow-ai/langflow-helm-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
    };

  chart_scan_langflow-runtime =
    let
      base_url = "https://langflow-ai.github.io/langflow-helm-charts";
      name = "langflow-runtime";
    in
    _chart_scan {
      inherit name base_url;
      chart_url = "https://github.com/langflow-ai/langflow-helm-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
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

  chart_scan_searxng = _chart_scan {
    name = "searxng";
    base_url = "https://charts.searxng.org";
    chart_url = "https://github.com/searxng/searxng-helm-chart/releases/download/searxng-{1}/searxng-{1}.tgz";
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

  chart_scan_kube-prometheus-stack = prometheus_chart {
    name = "kube-prometheus-stack";
    last = 80;
  };

  chart_scan_prometheus-adapter = prometheus_chart { name = "prometheus-adapter"; last = 10; };
  chart_scan_prometheus-cloudwatch-exporter = prometheus_chart { name = "prometheus-cloudwatch-exporter"; last = 10; };
  chart_scan_prometheus-elasticsearch-exporter = prometheus_chart { name = "prometheus-elasticsearch-exporter"; };
  chart_scan_prometheus-mongodb-exporter = prometheus_chart { name = "prometheus-mongodb-exporter"; last = 10; };
  chart_scan_prometheus-mysql-exporter = prometheus_chart { name = "prometheus-mysql-exporter"; last = 10; };
  chart_scan_prometheus-postgres-exporter = prometheus_chart { name = "prometheus-postgres-exporter"; };
  chart_scan_prometheus-pushgateway = prometheus_chart { name = "prometheus-pushgateway"; last = 10; };
  chart_scan_prometheus-redis-exporter = prometheus_chart { name = "prometheus-redis-exporter"; last = 10; };

  chart_scan_alloy = grafana_chart { name = "alloy"; };
  chart_scan_loki = grafana_chart { name = "loki"; prefix = "helm-"; };
  chart_scan_mimir = grafana_chart { name = "mimir-distributed"; filter_out = "weekly|rc"; };
  chart_scan_oncall = grafana_chart { name = "oncall"; };
  chart_scan_tempo = grafana_chart { name = "tempo-distributed"; filter_out = "weekly|rc"; };

  chart_scan_coroot-ce = coroot_chart { name = "coroot-ce"; };
  chart_scan_coroot-operator = coroot_chart { name = "coroot-operator"; };
  chart_scan_coroot-node-agent = coroot_chart { name = "node-agent"; };

  chart_scan_otf = _chart_scan rec {
    name = "otf";
    base_url = "https://jpetrucciani.github.io/otf-charts";
    chart_url = "https://github.com/jpetrucciani/otf-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
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

  chart_scan_fission = _chart_scan rec {
    name = "fission-all";
    exe_name = "fission";
    base_url = "https://fission.github.io/fission-charts";
    chart_url = "https://github.com/fission/fission-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
  };

  chart_scan_flipt = _chart_scan rec {
    name = "flipt";
    base_url = "https://helm.flipt.io";
    chart_url = "https://github.com/flipt-io/helm-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
  };

  chart_scan_oneuptime = _chart_scan rec {
    name = "oneuptime";
    base_url = "https://helm-chart.oneuptime.com";
    chart_url = "https://helm-chart.oneuptime.com/${name}-{1}.tgz";
  };

  chart_scan_plane = _chart_scan rec {
    name = "plane-ce";
    base_url = "https://helm.plane.so";
    chart_url = "https://github.com/makeplane/helm-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
  };

  # chart_scan_quickwit = _chart_scan rec {
  #   name = "quickwit";
  #   base_url = "https://helm.quickwit.io";
  #   chart_url = "https://github.com/quickwit-oss/helm-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
  # };

  chart_scan_dask-kubernetes-operator = _chart_scan rec {
    name = "dask-kubernetes-operator";
    base_url = "https://helm.dask.org";
    chart_url = "https://helm.dask.org/${name}-{1}.tgz";
  };

  chart_scan_kong-ingress = _chart_scan {
    name = "ingress";
    base_url = "https://charts.konghq.com";
    chart_url = "https://github.com/Kong/charts/releases/download/ingress-{1}/ingress-{1}.tgz";
  };

  chart_scan_open-webui = _chart_scan rec {
    name = "open-webui";
    base_url = "https://helm.openwebui.com";
    chart_url = "https://github.com/open-webui/helm-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
    last = 10;
  };

  chart_scan_sonarqube = _chart_scan {
    name = "sonarqube";
    base_url = "https://SonarSource.github.io/helm-chart-sonarqube";
    chart_url = "https://github.com/SonarSource/helm-chart-sonarqube/releases/download/sonarqube-{1 strip_plus}/sonarqube-{1}.tgz";
    last = 1; # something funky with their helm index?
  };

  chart_scan_aws_mountpoint-s3-csi-driver = _chart_scan {
    name = "aws-mountpoint-s3-csi-driver";
    base_url = "https://awslabs.github.io/mountpoint-s3-csi-driver";
    chart_url = "https://github.com/awslabs/mountpoint-s3-csi-driver/releases/download/helm-chart-aws-mountpoint-s3-csi-driver-{1}/aws-mountpoint-s3-csi-driver-{1}.tgz";
  };

  chart_scan_odoo = _chart_scan {
    name = "odoo";
    base_url = "https://imio.github.io/helm-charts";
    chart_url = "https://imio.github.io/helm-charts/odoo/odoo-{1}.tgz";
  };

  chart_scan_redpanda = _chart_scan {
    name = "operator";
    base_url = "https://charts.redpanda.com";
    chart_url = "https://github.com/redpanda-data/helm-charts/releases/download/operator-{1}/operator-{1}.tgz";
  };

  chart_scan_questdb = _chart_scan {
    name = "questdb";
    base_url = "https://helm.questdb.io";
    chart_url = "https://questdb.github.io/questdb-kubernetes/questdb-{1}.tgz";
  };

  chart_scan_semaphore = _chart_scan {
    name = "semaphore";
    base_url = "https://semaphoreui.github.io/charts";
    chart_url = "https://github.com/semaphoreui/charts/releases/download/semaphore-{1}/semaphore-{1}.tgz";
  };

  chart_scan_csi-driver-smb = _chart_scan {
    name = "csi-driver-smb";
    base_url = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts";
    chart_url = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts/{1}/csi-driver-smb-{1}.tgz";
  };

  helm_pog_scripts = [
    chart_scan_alloy
    chart_scan_argo-cd
    chart_scan_authentik
    chart_scan_aws_mountpoint-s3-csi-driver
    chart_scan_csi-driver-smb
    chart_scan_dask-kubernetes-operator
    chart_scan_external-secrets
    chart_scan_fission
    chart_scan_fleet
    chart_scan_flipt
    chart_scan_gitlab-runner
    chart_scan_infisical
    chart_scan_jupyterhub
    chart_scan_kube-prometheus-stack
    chart_scan_langflow-ide
    chart_scan_langflow-runtime
    chart_scan_linkerd-control-plane
    chart_scan_linkerd-crds
    chart_scan_loki
    chart_scan_mimir
    chart_scan_mongo-operator
    chart_scan_nfs
    chart_scan_odoo
    chart_scan_oncall
    chart_scan_oneuptime
    chart_scan_open-webui
    chart_scan_otf
    chart_scan_plane
    chart_scan_postgres-operator
    chart_scan_postgres-operator-ui
    chart_scan_prometheus-adapter
    chart_scan_prometheus-cloudwatch-exporter
    chart_scan_prometheus-elasticsearch-exporter
    chart_scan_prometheus-mongodb-exporter
    chart_scan_prometheus-mysql-exporter
    chart_scan_prometheus-postgres-exporter
    chart_scan_prometheus-pushgateway
    chart_scan_prometheus-redis-exporter
    chart_scan_questdb
    chart_scan_redis-operator
    chart_scan_redpanda
    chart_scan_robusta
    chart_scan_searxng
    chart_scan_semaphore
    chart_scan_sentry
    chart_scan_signoz
    chart_scan_sonarqube
    chart_scan_stackstorm
    chart_scan_tempo
    chart_scan_traefik
  ];
}
