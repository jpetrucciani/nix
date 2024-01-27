nixpkgs: SPELL:
let
  inherit (builtins) functionArgs isFunction intersectAttrs;
  pkgs = import nixpkgs { };
  k8s = rec {
    addons = import ./k8s/addons.nix params;
    airbyte = import ./k8s/airbyte.nix params;
    argocd = import ./k8s/argocd.nix params;
    authentik = import ./k8s/authentik.nix params;
    aws = import ./k8s/aws.nix (params // { inherit services; });
    cert-manager = import ./k8s/cert-manager.nix params;
    cron = import ./k8s/cron.nix params;
    datadog = import ./k8s/datadog.nix params;
    elastic = import ./k8s/elastic.nix params;
    external-secrets = import ./k8s/external-secrets.nix params;
    fission = import ./k8s/fission.nix params;
    flipt = import ./k8s/flipt.nix params;
    gitlab-runner = import ./k8s/gitlab-runner.nix params;
    grafana = import ./k8s/grafana.nix params;
    helm = import ./k8s/helm.nix params;
    infisical = import ./k8s/infisical.nix params;
    jupyterhub = import ./k8s/jupyterhub.nix params;
    linkerd = import ./k8s/linkerd.nix params;
    mongo = import ./k8s/mongo.nix params;
    nginx-ingress = import ./k8s/nginx-ingress.nix params;
    otf = import ./k8s/otf.nix params;
    postgres = import ./k8s/postgres.nix params;
    prometheus = import ./k8s/prometheus.nix params;
    rancher = import ./k8s/rancher.nix params;
    redis = import ./k8s/redis.nix params;
    robusta = import ./k8s/robusta.nix params;
    sentry = import ./k8s/sentry.nix params;
    services = import ./k8s/services.nix params;
    signoz = import ./k8s/signoz.nix params;
    stackstorm = import ./k8s/stackstorm.nix params;
    tailscale = import ./k8s/tailscale.nix params;
    traefik = import ./k8s/traefik.nix params;
    whoogle = import ./k8s/whoogle.nix params;
    woodpecker = import ./k8s/woodpecker.nix params;
    _ = {
      version = chart_url_fn: v: s: args: chart_url_fn (args // { version = v; sha256 = s; });
      chart = { defaults, chart_url, extraSets ? [ ] }:
        { name ? defaults.name
        , namespace ? defaults.namespace
        , values ? [ ]
        , sets ? [ ] ++ extraSets
        , version ? defaults.version
        , sha256 ? defaults.sha256
        , forceNamespace ? true
        , extraFlags ? [ ]
        , sortYaml ? false
        , preRender ? ""
        , postRender ? ""
        }: hex.k8s.helm.build {
          inherit name namespace values sets version sha256 forceNamespace sortYaml preRender postRender;
          extraFlags = extraFlags ++ [ "--version=${version}" ];
          url = chart_url version;
        };
    };
  };
  hex = (import ./hex.nix pkgs) // { inherit k8s; };
  params = { inherit hex pkgs; };
  spell = import SPELL;
  output = if isFunction spell then spell (intersectAttrs (functionArgs spell) params) else spell;
in
output
