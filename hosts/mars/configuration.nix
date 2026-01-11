{ config, flake, machine-name, pkgs, ... }:
let
  hostname = "mars";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./hardware-configuration.nix
  ];

  inherit (common) zramSwap;

  nix = common.nix // {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/jacobi/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  home-manager.users.jacobi = common.jacobi;

  boot = {
    initrd.systemd.network.wait-online.enable = false;
    kernel.sysctl = { } // common.sysctl_opts;
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 3;
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };
  };
  systemd.network.wait-online.enable = false;

  environment = {
    etc."nixpkgs-path".source = common.pkgs.path;
    systemPackages = with pkgs; [
      nano
      wget
      foot
      kitty
      waybar
      hyprpaper
      git
    ];
    variables = {
      NIX_HOST = hostname;
      NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
      NIXOS_OZONE_WL = "1";
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
  };

  time.timeZone = common.timeZone;

  networking = {
    hostName = hostname;
  };

  i18n.defaultLocale = common.defaultLocale;
  i18n.extraLocaleSettings = common.extraLocaleSettings;

  users.users.jacobi = {
    isNormalUser = true;
    description = "jacobi";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    openssh.authorizedKeys.keys = with common.pubkeys; usual;
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  services.tailscale.enable = true;
  services.openssh.enable = true;
  networking.firewall.enable = false;
  system.stateVersion = "25.11";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
