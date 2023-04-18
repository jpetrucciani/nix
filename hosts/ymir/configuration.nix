{ config, machine-name, pkgs, ... }:
let
  hostname = "ymir";
  common = import ../common.nix { inherit config machine-name pkgs; };
  nixos-hardware = fetchTarball { url = "https://github.com/NixOS/nixos-hardware/archive/25010a042c23695ae457a97aad60e9b1d49f2ecc.tar.gz"; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    "${nixos-hardware}/dell/xps/15-9560"
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

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.kernel.sysctl = { } // common.sysctl_opts;
  boot.kernelParams = [ "acpi_rev_override=1" ];
  boot.tmp.useTmpfs = true;

  environment.etc."nixpkgs-path".source = common.pinned.path;
  environment.variables = {
    NIX_HOST = hostname;
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
  };

  networking.hostName = hostname;
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  time.timeZone = common.timeZone;
  i18n.defaultLocale = common.defaultLocale;
  i18n.extraLocaleSettings = common.extraLocaleSettings;

  # Configure keymap in X11
  services = {
    xserver = {
      enable = true;
      layout = "us";
      xkbVariant = "";
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      libinput.enable = true;
    };
    printing.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  } // common.services;

  sound.enable = true;
  hardware.pulseaudio.enable = false;

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
  system.stateVersion = "23.05";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
