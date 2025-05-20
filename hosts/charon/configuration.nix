{ config, flake, machine-name, pkgs, ... }:
let
  # inherit (lib.attrsets) mapAttrs' nameValuePair;

  hostname = "charon";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
  configPath = "/Users/jacobi/cfg/hosts/${hostname}/configuration.nix";
  username = "jacobi";

  # runner-defaults = {
  #   enable = true;
  #   replace = true;
  #   url = "https://github.com/jpetrucciani/nix";
  #   extraLabels = [ "nix" "m1" ];
  # };
in
{
  imports = [
    "${common.home-manager}/nix-darwin"
  ];

  home-manager.users.jacobi = common.jacobi;
  documentation.enable = false;

  time.timeZone = common.timeZone;
  environment.variables = {
    NIX_HOST = hostname;
    NIXDARWIN_CONFIG = configPath;
  };
  environment.darwinConfig = configPath;

  users.users.jacobi = {
    name = username;
    home = "/Users/${username}";
    openssh.authorizedKeys.keys = with common.pubkeys; [
      galaxyboss
      milkyway
      pluto
    ];
  };

  system.stateVersion = 4;
  nix = common.nix // {
    nixPath = [
      "darwin=${common.nix-darwin}"
      "darwin-config=${configPath}"
    ];
  };

  ### can't get this working?
  # services.github-runners = mapAttrs' nameValuePair {
  #   jpetrucciani-nix = runner-defaults // {
  #     extraPackages = with pkgs; [ gh cachix ];
  #     tokenFile = "/etc/default/gh.token";
  #   };
  # };
  # services.prometheus.exporters.node.enable = true;
}
