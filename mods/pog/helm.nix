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
  prefect_chart = { name }: _chart_scan {
    inherit name;
    base_url = "https://prefecthq.github.io/prefect-helm";
    chart_url = "https://prefecthq.github.io/prefect-helm/charts/${name}-{1}.tgz";
  };
  trino_chart = { name }: _chart_scan {
    inherit name;
    base_url = "https://trinodb.github.io/charts";
    chart_url = "https://github.com/trinodb/charts/releases/download/${name}-{1}/${name}-{1}.tgz";
  };

  ocihash = final.pog {
    name = "ocihash";
    description = "hash helm charts from an oci registry";
    flags = [
      { name = "url"; }
      { name = "tag"; }
    ];
    script = ''
      set -euo pipefail

      if [ -z "''${url:-}" ]; then
        die "--url is required"
      fi
      if [ -z "''${tag:-}" ]; then
        die "--tag is required"
      fi

      url="''${url#oci://}"
      ref="''${url}:''${tag}"
      tmpDir=$(mktemp -d)
      # shellcheck disable=SC2064
      trap "rm -rf $tmpDir" EXIT
      ${final.skopeo}/bin/skopeo --insecure-policy copy --format oci "docker://$ref" "dir:$tmpDir" >&2

      manifest="$tmpDir/manifest.json"
      if [ ! -s "$manifest" ]; then
        die "skopeo did not write an OCI manifest for $ref"
      fi

      chart_blob=$(${final.jq}/bin/jq -er '
        [
          .layers[]
          | select(.mediaType == "application/vnd.cncf.helm.chart.content.v1.tar+gzip")
          | .digest
          | sub("^sha256:"; "")
        ][0] // empty
      ' "$manifest")
      blob_path="$tmpDir/$chart_blob"
      if [ ! -f "$blob_path" ]; then
        die "chart blob $chart_blob from $ref is missing after skopeo copy"
      fi

      outDir="$tmpDir/chart"
      mkdir -p "$outDir"
      ${final.gnutar}/bin/tar -xzf "$blob_path" --strip-components=1 -C "$outDir"
      if [ -z "$(${final.coreutils}/bin/ls -A "$outDir")" ]; then
        die "extracted chart for $ref is empty"
      fi

      ${final._nix}/bin/nix-hash --type sha256 --base32 "$outDir"
    '';
  };

  v_format = final.writeTextFile {
    name = "v_format.py";
    text = ''
      import json
      import sys
      from datetime import datetime

      data = json.load(open(sys.argv[1]))

      def _format_date(raw: str) -> str:
          if not raw:
              return ""
          try:
              return datetime.fromisoformat(raw.replace("Z", "+00:00")).strftime("%Y-%m-%d")
          except ValueError:
              return raw.split("T")[0]

      def _format(entry: dict[str, str]) -> str:
          version = entry["version"]
          sha256 = entry["sha256"]
          date = _format_date(entry.get("date", ""))
          attr = version.replace(".", "-").strip().split("+")[0]
          prefix = "v" if attr[0] != "v" else ""
          suffix = f" # {date}" if date else ""
          return f'{prefix}{attr} = _v "{version}" "{sha256}";{suffix}'

      print("\n".join(_format(x) for x in data))
    '';
  };

  chart_scan_flags = last: [
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
    {
      name = "upsert";
      description = "upsert the chart versions into a json file. creates if it doesn't exist";
    }
  ];

  emit_chart_scan = { jq, yq }: helpers:
    with helpers; ''
      if [[ -n "''${upsert:-}" ]]; then
        existing='[]'
        if [[ -f "$upsert" ]] && [[ -s "$upsert" ]]; then
          existing="$(cat "$upsert")"
        fi

        # shellcheck disable=SC2016
        ${jq} -n --argjson existing "$existing" --slurpfile new "$final_json" '
          $existing + $new[0]
          | group_by(.version)
          | map(max_by(.date))
          | sort_by(.date)
          | reverse
        ' > "''${upsert}.tmp"

        mv "''${upsert}.tmp" "$upsert"
        exit 0
      fi

      if ${flag "vformat"}; then
        ${final.python3}/bin/python ${v_format} "$final_json"
      else
        ${yq} "$final_json"
      fi
    '';

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
    in
    final.pog {
      name = "chart_scan_${exe_name}";
      description = "a quick and easy way to get the latest x releases of the '${exe_name}' chart!";
      flags = chart_scan_flags last;
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
            ${parallel} --rpl '{strip_plus} s/(.*)\+.*/\1/;' --rpl '{ymd} s/(.*)T.*/\1/;' 'echo -n "{1},{=2 uq(); =},"; nix-prefetch-url --unpack "${chart_url}" 2>/dev/null || echo ERR_404' >>"$temp_csv"

        debug "formed json into csv at $temp_csv"
        err_404="$(<"$temp_csv" ${final.gnugrep}/bin/grep 'ERR_404' || true)"
        if [ -n "$err_404" ]; then
          debug "chart files not found for the following versions:"
          debug "$err_404"
        fi

        # format as json
        ${final.gnugrep}/bin/grep -v 'ERR_404' "$temp_csv" | ${yq} -p=csv -o=json >"$final_json"
      '' + (emit_chart_scan { inherit jq yq; } helpers);
    };

  _oci_chart_scan =
    { name
    , exe_name ? name
    , repo
    , last ? 20
    , filter_out ? ""
    }:
    let
      inherit (final.lib) getExe removePrefix;
      jq = getExe final.jaq;
      yq = "${final.yq-go}/bin/yq";
      oras = getExe final.oras;
      ocihash_bin = getExe ocihash;
      registry = removePrefix "oci://" repo;
      parallel = "${final.parallel}/bin/parallel --will-cite --keep-order -j0 --colsep ' '";
      _filter = if (builtins.stringLength filter_out) > 0 then ''${final.gnused}/bin/sed -E -e '/${filter_out}/d' | '' else "";
      scan_oci_tag = final.writeShellScript "scan-oci-helm-chart-tag" ''
        set -euo pipefail

        repo="$1"
        tag="$2"
        date="$(${oras} manifest fetch --format json "$repo:$tag" 2>/dev/null | ${jq} -r '.content.annotations["org.opencontainers.image.created"] // ""' || true)"
        err_log="$(${final.coreutils}/bin/mktemp)"
        trap 'rm -f "$err_log"' EXIT
        if ! sha256="$(${ocihash_bin} --url "oci://$repo" --tag "$tag" 2>"$err_log" | ${final.coreutils}/bin/tail -n 1)"; then
          ${final.coreutils}/bin/cat "$err_log" >&2
          printf '%s,%s,ERR_OCI\n' "$tag" "$date"
          exit 0
        fi
        if [ -z "$sha256" ]; then
          ${final.coreutils}/bin/cat "$err_log" >&2
          printf 'ocihash returned no hash for %s:%s\n' "$repo" "$tag" >&2
          printf '%s,%s,ERR_OCI\n' "$tag" "$date"
          exit 0
        fi
        printf '%s,%s,%s\n' "$tag" "$date" "$sha256"
      '';
    in
    final.pog {
      name = "chart_scan_${exe_name}";
      description = "a quick and easy way to get the latest x releases of the '${exe_name}' OCI chart!";
      flags = chart_scan_flags last;
      shortDefaultFlags = false;
      script = helpers: with helpers; ''
        temp_tags=${tmp.json}
        temp_versions=${tmp.txt}
        temp_csv=${tmp.csv}
        final_json=${tmp.json}

        ${oras} repo tags --exclude-digest-tags --format json '${registry}' >"$temp_tags"

        debug "pulled OCI chart tags to $temp_tags"

        ${jq} -r '.tags[]' <"$temp_tags" |
            ${_filter}
            ${final.coreutils}/bin/sort -V |
            ${final.coreutils}/bin/tail -n "$last" |
            ${final.coreutils}/bin/tac >"$temp_versions"

        debug "selected OCI chart versions into $temp_versions"

        echo "version,date,sha256" >>"$temp_csv"
        ${parallel} '${scan_oci_tag} "${registry}" "{1}"' <"$temp_versions" >>"$temp_csv"

        debug "formed json into csv at $temp_csv"
        err_oci="$(<"$temp_csv" ${final.gnugrep}/bin/grep 'ERR_OCI' || true)"
        if [ -n "$err_oci" ]; then
          debug "OCI chart artifacts not found for the following versions:"
          debug "$err_oci"
        fi

        ${final.gnugrep}/bin/grep -v 'ERR_OCI' "$temp_csv" | ${yq} -p=csv -o=json >"$final_json"
      '' + (emit_chart_scan { inherit jq yq; } helpers);
    };

  chart_scanners = {
    airbyte = _chart_scan {
      name = "airbyte";
      base_url = "https://airbytehq.github.io/helm-charts";
      filter_out = "alpha|beta|rc";
    };

    airflow = _chart_scan {
      name = "airflow";
      base_url = "https://airflow.apache.org";
      chart_url = "https://downloads.apache.org/airflow/helm-chart/{1}/airflow-{1}.tgz";
    };

    alloy = grafana_chart { name = "alloy"; };

    argo-cd = _chart_scan {
      name = "argo-cd";
      base_url = "https://argoproj.github.io/argo-helm";
      chart_url = "https://github.com/argoproj/argo-helm/releases/download/argo-cd-{1}/argo-cd-{1}.tgz";
      last = 100;
    };

    argo-workflows = _chart_scan {
      name = "argo-workflows";
      base_url = "https://argoproj.github.io/argo-helm";
      chart_url = "https://github.com/argoproj/argo-helm/releases/download/argo-workflows-{1}/argo-workflows-{1}.tgz";
    };

    authentik = _chart_scan {
      name = "authentik";
      base_url = "https://charts.goauthentik.io";
      chart_url = "https://github.com/goauthentik/helm/releases/download/authentik-{1}/authentik-{1}.tgz";
    };

    aws_mountpoint-s3-csi-driver = _chart_scan {
      name = "aws-mountpoint-s3-csi-driver";
      base_url = "https://awslabs.github.io/mountpoint-s3-csi-driver";
      chart_url = "https://github.com/awslabs/mountpoint-s3-csi-driver/releases/download/helm-chart-aws-mountpoint-s3-csi-driver-{1}/aws-mountpoint-s3-csi-driver-{1}.tgz";
    };

    cert-manager = _chart_scan {
      name = "cert-manager";
      base_url = "https://charts.jetstack.io";
      chart_url = "https://charts.jetstack.io/charts/cert-manager-{1}.tgz";
      filter_out = "alpha|beta|dev";
    };

    coroot-ce = coroot_chart { name = "coroot-ce"; };
    coroot-node-agent = coroot_chart { name = "node-agent"; };
    coroot-operator = coroot_chart { name = "coroot-operator"; };

    csi-driver-smb = _chart_scan {
      name = "csi-driver-smb";
      base_url = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts";
      chart_url = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts/{1}/csi-driver-smb-{1}.tgz";
    };

    dask-kubernetes-operator = _chart_scan rec {
      name = "dask-kubernetes-operator";
      base_url = "https://helm.dask.org";
      chart_url = "https://helm.dask.org/${name}-{1}.tgz";
    };

    deepgram = _chart_scan {
      name = "deepgram-self-hosted";
      base_url = "https://deepgram.github.io/self-hosted-resources";
      chart_url = "https://github.com/deepgram/self-hosted-resources/releases/download/deepgram-self-hosted-{1}/deepgram-self-hosted-{1}.tgz";
    };

    dremio = _oci_chart_scan {
      name = "dremio";
      repo = "quay.io/dremio/dremio-helm";
      filter_out = "public-preview";
    };

    external-secrets = _chart_scan {
      name = "external-secrets";
      base_url = "https://charts.external-secrets.io";
      chart_url = "https://github.com/external-secrets/external-secrets/releases/download/helm-chart-{1}/external-secrets-{1}.tgz";
      filter_out = "alpha|beta|dev|rc";
    };

    fission = _chart_scan rec {
      name = "fission-all";
      exe_name = "fission";
      base_url = "https://fission.github.io/fission-charts";
      chart_url = "https://github.com/fission/fission-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
    };

    fleet = _chart_scan {
      name = "fleet";
      base_url = "https://fleetdm.github.io/fleet/charts";
      chart_url = "https://fleetdm.github.io/fleet/charts/fleet-{1}.tgz";
    };

    flipt = _chart_scan rec {
      name = "flipt";
      base_url = "https://helm.flipt.io";
      chart_url = "https://github.com/flipt-io/helm-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
    };

    gitlab-runner = _chart_scan {
      name = "gitlab-runner";
      base_url = "https://gitlab-charts.s3.amazonaws.com";
    };

    infisical = _chart_scan {
      name = "infisical";
      base_url = "https://dl.cloudsmith.io/public/infisical/helm-charts/helm/charts";
    };

    jupyterhub = _chart_scan {
      name = "jupyterhub";
      base_url = "https://hub.jupyter.org/helm-chart";
      filter_out = "alpha|beta|dev";
    };

    kong-ingress = _chart_scan {
      name = "ingress";
      base_url = "https://charts.konghq.com";
      chart_url = "https://github.com/Kong/charts/releases/download/ingress-{1}/ingress-{1}.tgz";
    };

    kube-prometheus-stack = prometheus_chart {
      name = "kube-prometheus-stack";
      last = 80;
    };

    langflow-ide =
      let
        base_url = "https://langflow-ai.github.io/langflow-helm-charts";
        name = "langflow-ide";
      in
      _chart_scan {
        inherit name base_url;
        chart_url = "https://github.com/langflow-ai/langflow-helm-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
      };

    langflow-runtime =
      let
        base_url = "https://langflow-ai.github.io/langflow-helm-charts";
        name = "langflow-runtime";
      in
      _chart_scan {
        inherit name base_url;
        chart_url = "https://github.com/langflow-ai/langflow-helm-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
      };

    linkerd-control-plane = _chart_scan {
      name = "linkerd-control-plane";
      base_url = "https://helm.linkerd.io/stable";
    };

    linkerd-crds = _chart_scan {
      name = "linkerd-crds";
      base_url = "https://helm.linkerd.io/stable";
    };

    livekit = _chart_scan {
      name = "livekit-server";
      base_url = "https://helm.livekit.io";
      chart_url = "https://helm.livekit.io/livekit-server-{1}.tgz";
    };

    loki = grafana_chart { name = "loki"; prefix = "helm-"; };

    mimir = grafana_chart { name = "mimir-distributed"; filter_out = "weekly|rc"; };

    mongo-operator = _chart_scan rec {
      name = "community-operator";
      exe_name = "mongo-operator";
      base_url = "https://mongodb.github.io/helm-charts";
      chart_url = "https://github.com/mongodb/helm-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
    };

    nats = _chart_scan {
      name = "nats";
      base_url = "https://nats-io.github.io/k8s/helm/charts";
      chart_url = "https://github.com/nats-io/k8s/releases/download/nats-{1}/nats-{1}.tgz";
    };

    netbox = _chart_scan {
      name = "netbox";
      base_url = "https://charts.netbox.oss.netboxlabs.com";
      chart_url = "https://github.com/netbox-community/netbox-chart/releases/download/netbox-{1}/netbox-{1}.tgz";
    };

    netbox_diode = _chart_scan {
      name = "diode";
      base_url = "https://netboxlabs.github.io/diode/charts";
      chart_url = "https://github.com/netboxlabs/diode/releases/download/helm-chart-diode-{1}/diode-{1}.tgz";
    };

    nfs = let chart = "nfs-subdir-external-provisioner"; in
      _chart_scan {
        name = "nfs";
        chart_name = chart;
        base_url = "https://kubernetes-sigs.github.io/${chart}";
        chart_url = "https://github.com/kubernetes-sigs/${chart}/releases/download/${chart}-{1}/${chart}-{1}.tgz";
      };

    odoo = _chart_scan {
      name = "odoo";
      base_url = "https://imio.github.io/helm-charts";
      chart_url = "https://imio.github.io/helm-charts/odoo/odoo-{1}.tgz";
    };

    oncall = grafana_chart { name = "oncall"; };

    oneuptime = _chart_scan rec {
      name = "oneuptime";
      base_url = "https://helm-chart.oneuptime.com";
      chart_url = "https://helm-chart.oneuptime.com/${name}-{1}.tgz";
    };

    open-webui = _chart_scan rec {
      name = "open-webui";
      base_url = "https://helm.openwebui.com";
      chart_url = "https://github.com/open-webui/helm-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
      last = 10;
    };

    otf = _chart_scan rec {
      name = "otfd";
      base_url = "https://leg100.github.io/otf-charts";
      chart_url = "https://github.com/leg100/otf-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
    };

    plane = _chart_scan rec {
      name = "plane-ce";
      base_url = "https://helm.plane.so";
      chart_url = "https://github.com/makeplane/helm-charts/releases/download/${name}-{1}/${name}-{1}.tgz";
    };

    postgres-operator = _chart_scan {
      name = "postgres-operator";
      base_url = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator";
    };

    postgres-operator-ui = _chart_scan {
      name = "postgres-operator-ui";
      base_url = "https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui";
    };

    prefect-server = prefect_chart { name = "prefect-server"; };
    prefect-worker = prefect_chart { name = "prefect-worker"; };

    prometheus-adapter = prometheus_chart { name = "prometheus-adapter"; last = 10; };
    prometheus-cloudwatch-exporter = prometheus_chart { name = "prometheus-cloudwatch-exporter"; last = 10; };
    prometheus-elasticsearch-exporter = prometheus_chart { name = "prometheus-elasticsearch-exporter"; };
    prometheus-mongodb-exporter = prometheus_chart { name = "prometheus-mongodb-exporter"; last = 10; };
    prometheus-mysql-exporter = prometheus_chart { name = "prometheus-mysql-exporter"; last = 10; };
    prometheus-nats-exporter = prometheus_chart { name = "prometheus-nats-exporter"; last = 10; };
    prometheus-postgres-exporter = prometheus_chart { name = "prometheus-postgres-exporter"; };
    prometheus-pushgateway = prometheus_chart { name = "prometheus-pushgateway"; last = 10; };
    prometheus-redis-exporter = prometheus_chart { name = "prometheus-redis-exporter"; last = 10; };

    questdb = _chart_scan {
      name = "questdb";
      base_url = "https://helm.questdb.io";
      chart_url = "https://questdb.github.io/questdb-kubernetes/questdb-{1}.tgz";
    };

    redis-operator = _chart_scan rec {
      name = "redis-operator";
      base_url = "https://spotahome.github.io/redis-operator";
      chart_url = "https://github.com/spotahome/${name}/releases/download/Chart-{1}/${name}-{1}.tgz";
    };

    redpanda = _chart_scan {
      name = "operator";
      base_url = "https://charts.redpanda.com";
      chart_url = "https://github.com/redpanda-data/redpanda-operator/releases/download/operator/v{1}/operator-{1}.tgz";
      filter_out = "beta";
    };

    retool = _chart_scan {
      name = "retool";
      base_url = "https://charts.retool.com";
      chart_url = "https://charts.retool.com/retool-{1}.tgz";
    };

    robusta = _chart_scan {
      name = "robusta";
      base_url = "https://robusta-charts.storage.googleapis.com";
    };

    searxng = _chart_scan {
      name = "searxng";
      base_url = "https://charts.searxng.org";
      chart_url = "https://github.com/searxng/searxng-helm-chart/releases/download/searxng-{1}/searxng-{1}.tgz";
    };

    semaphore = _chart_scan {
      name = "semaphore";
      base_url = "https://semaphoreui.github.io/charts";
      chart_url = "https://github.com/semaphoreui/charts/releases/download/semaphore-{1}/semaphore-{1}.tgz";
    };

    sentry = _chart_scan {
      name = "sentry";
      base_url = "https://sentry-kubernetes.github.io/charts";
    };

    signoz = _chart_scan {
      name = "signoz";
      base_url = "https://charts.signoz.io";
      chart_url = "https://github.com/SigNoz/charts/releases/download/signoz-{1}/signoz-{1}.tgz";
    };

    sonarqube = _chart_scan {
      name = "sonarqube";
      base_url = "https://SonarSource.github.io/helm-chart-sonarqube";
      chart_url = "https://github.com/SonarSource/helm-chart-sonarqube/releases/download/sonarqube-{1 strip_plus}/sonarqube-{1}.tgz";
      last = 1; # something funky with their helm index?
    };

    stackstorm = _chart_scan {
      name = "stackstorm";
      chart_name = "stackstorm-ha";
      base_url = "https://helm.stackstorm.com";
    };

    superset = _chart_scan {
      name = "superset";
      chart_name = "superset";
      base_url = "http://apache.github.io/superset";
      chart_url = "https://github.com/apache/superset/releases/download/superset-helm-chart-{1}/superset-{1}.tgz";
    };

    tempo = _oci_chart_scan {
      name = "tempo-distributed";
      repo = "oci://ghcr.io/grafana-community/helm-charts/tempo-distributed";
      filter_out = "weekly|rc";
    };

    traefik = let base = "https://traefik.github.io/charts"; in
      _chart_scan {
        name = "traefik";
        base_url = base;
        chart_url = "${base}/traefik/traefik-{1}.tgz";
        filter_out = "ea|rc|alpha";
      };

    trino = trino_chart { name = "trino"; };
    trino-gateway = trino_chart { name = "trino-gateway"; };
  };

  chart_scan_attrs = prev.lib.mapAttrs'
    (name: scanner: prev.lib.nameValuePair "chart_scan_${name}" scanner)
    chart_scanners;

  unlisted_chart_scan_names = [
    "coroot-ce"
    "coroot-node-agent"
    "coroot-operator"
    "deepgram"
    "kong-ingress"
    "netbox_diode"
  ];

  listed_chart_scan_attrs =
    prev.lib.removeAttrs chart_scan_attrs
      (map (name: "chart_scan_${name}") unlisted_chart_scan_names);
in
chart_scan_attrs // {
  inherit _chart_scan _oci_chart_scan ocihash;
  helm_pog_scripts = prev.lib.attrValues listed_chart_scan_attrs;
}
