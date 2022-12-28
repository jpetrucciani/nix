{ config, pkgs, ... }:
let
  hostname = "luna";
  common = import ../common.nix { inherit config pkgs; };
in
{
  imports = [
    "${common.home-manager.path}/nixos"
    "${common.mms}/nixos/modules/services/games/minecraft-servers"
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
  networking.networkmanager.enable = true;

  i18n.defaultLocale = common.defaultLocale;
  i18n.extraLocaleSettings = common.extraLocaleSettings;

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
    inherit (common._services) blocky;
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
      videoDrivers = [ "amdgpu" ];
      layout = "us";
      xkbVariant = "";
    };
    modded-minecraft-servers = with common.minecraft; {
      eula = true;
      instances = {
        rlcraft = {
          inherit (conf) jvmOpts;
          enable = true;
          rsyncSSHKeys = [ common.pubkeys.pluto ];
          jvmPackage = conf.jre8;
          jvmInitialAllocation = "8G";
          jvmMaxAllocation = "10G";
          serverConfig =
            conf.defaults
              // {
              server-port = 25569;
              rcon-port = 25568;
              motd = "jacobi's rlcraft server";

              # rlcraft specific settings
              difficulty = 3;
              max-tick-time = -1;
              enable-command-block = true;
            };
        };
        vaulthunters = {
          inherit (conf) jvmOpts;
          enable = true;
          rsyncSSHKeys = [ common.pubkeys.pluto ];
          jvmPackage = conf.jre17;
          jvmInitialAllocation = "8G";
          jvmMaxAllocation = "10G";
          serverConfig =
            conf.defaults
              // {
              server-port = 25570;
              rcon-port = 25571;
              motd = "jacobi's vaulthunter server";
            };
        };
      };
    };
  } // common.services;
  virtualisation.docker.enable = true;

  system.stateVersion = "22.11";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
