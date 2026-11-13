{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    aq
    curl
    ghostty.terminfo
    jq
    lsof
    ncdu
    ripgrep
  ];

  programs.command-not-found.enable = lib.mkDefault false;

  nix.settings = {
    keep-going = lib.mkDefault true;
    extra-experimental-features = lib.mkDefault [ "nix-command" "flakes" ];
    substituters = [ "https://cache.g7c.us" ];
    trusted-public-keys = [ "cache.g7c.us:dSWpE2B5zK/Fahd7npIQWM4izRnVL+a4LiCAnrjdoFY=" ];
  };

  system.activationScripts.system-diff = {
    supportsDryActivation = lib.mkDefault true;
    text = lib.mkDefault ''
      if [ -e /run/current-system ]; then
        PATH=${lib.makeBinPath [ config.nix.package ]}:$PATH ${lib.getExe pkgs.nvd} --color=always diff /run/current-system "$systemConfig"
      fi
    '';
  };
}
