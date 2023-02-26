SPELL:
with builtins;
let
  nixpkgs = fromJSON (readFile ./nixpkgs.json);
  pkgs = import
    (fetchTarball
      {
        inherit (nixpkgs) sha256;
        url = "https://github.com/NixOS/nixpkgs/archive/${nixpkgs.rev}.tar.gz";
      })
    { };
  k8s = {
    addons = import ./k8s/addons.nix params;
    argocd = import ./k8s/argocd.nix params;
    authentik = import ./k8s/authentik.nix params;
    cert-manager = import ./k8s/cert-manager.nix params;
    cron = import ./k8s/cron.nix params;
    datadog = import ./k8s/datadog.nix params;
    external-secrets = import ./k8s/external-secrets.nix params;
    gitlab-runner = import ./k8s/gitlab-runner.nix params;
    helm = import ./k8s/helm.nix params;
    infisical = import ./k8s/infisical.nix params;
    nginx-ingress = import ./k8s/nginx-ingress.nix params;
    prometheus = import ./k8s/prometheus.nix params;
    rancher = import ./k8s/rancher.nix params;
    services = import ./k8s/services.nix params;
    signoz = import ./k8s/signoz.nix params;
    stackstorm = import ./k8s/stackstorm.nix params;
    tailscale = import ./k8s/tailscale.nix params;
    traefik = import ./k8s/traefik.nix params;
    whoogle = import ./k8s/whoogle.nix params;
    woodpecker = import ./k8s/woodpecker.nix params;
  };
  hex = (import ./hex.nix pkgs) // { inherit k8s; };
  params = { inherit hex pkgs; };
  spell = import SPELL;
  output = if isFunction spell then spell (intersectAttrs (functionArgs spell) params) else spell;
in
output
