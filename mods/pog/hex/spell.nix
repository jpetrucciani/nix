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
    cron = import ./k8s/cron.nix { inherit hex pkgs; };
    helm = import ./k8s/helm.nix { inherit hex pkgs; };
    services = import ./k8s/services.nix { inherit hex pkgs; };
    traefik = import ./k8s/traefik.nix { inherit hex pkgs; };
  };
  hex = (import ./hex.nix pkgs) // { inherit k8s; };
  spell = import SPELL;
  output = if isFunction spell then spell { inherit hex pkgs; } else spell;
in
output
