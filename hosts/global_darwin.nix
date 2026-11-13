{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    aq
    curl
    ghostty-bin.terminfo
    jq
    lsof
    ncdu
    ripgrep
  ];

  nix.settings = lib.mkIf config.nix.enable {
    keep-going = lib.mkDefault true;
    extra-experimental-features = lib.mkDefault [ "nix-command" "flakes" ];
    substituters = [ "https://cache.g7c.us" ];
    trusted-public-keys = [ "cache.g7c.us:dSWpE2B5zK/Fahd7npIQWM4izRnVL+a4LiCAnrjdoFY=" ];
  };

  system.activationScripts = {
    system-diff.text = lib.mkDefault ''
      if [ -e /run/current-system ]; then
        ${lib.getExe pkgs.nvd} --color=always diff /run/current-system "$systemConfig"
      fi
    '';
    preActivation.text = lib.mkBefore config.system.activationScripts.system-diff.text;
  };
}
