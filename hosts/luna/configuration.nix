{ config, pkgs, ... }:
let
  hostname = "luna";
  common = import ../common.nix { inherit config pkgs; };
in
{
  imports = [
    "${common.home-manager.path}/nixos"
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
  nixpkgs.pkgs = common.pinned;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.kernel.sysctl = { } // common.sysctl_opts;
  boot.tmpOnTmpfs = true;

  environment.etc."nixpkgs-path".source = common.pinned.path;
  environment.variables = {
    NIX_HOST = hostname;
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
  };

  time.timeZone = common.timeZone;

  networking.hostName = hostname;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  networking.networkmanager.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  users.users.jacobi = {
    isNormalUser = true;
    description = "jacobi";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      firefox
    ];
    openssh.authorizedKeys.keys = with common.pubkeys; [
      m1max
      nix-m1max
    ] ++ usual;
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [ ];

  networking.firewall.enable = false;
  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    xserver = {
      enable = true;
      displayManager.lightdm.enable = true;
      desktopManager.xfce.enable = true;
      layout = "us";
      xkbVariant = "";
    };
  } // common.services;
  virtualisation.docker.enable = true;

  system.stateVersion = "22.11";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
