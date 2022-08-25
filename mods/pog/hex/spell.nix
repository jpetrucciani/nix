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
    cron = import ./k8s/cron.nix params;
    helm = import ./k8s/helm.nix params;
    nginx-ingress = import ./k8s/nginx-ingress.nix params;
    services = import ./k8s/services.nix params;
    traefik = import ./k8s/traefik.nix params;
  };
  hex = (import ./hex.nix pkgs) // { inherit k8s; };
  params = { inherit hex pkgs; };
  spell = import SPELL;
  output = if isFunction spell then spell (intersectAttrs (functionArgs spell) params) else spell;
in
output
