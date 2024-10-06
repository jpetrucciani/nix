{ config, flake, machine-name, pkgs, ... }:
let
  inherit (flake.inputs) nixos-hardware;
  hostname = "proteus";
  ts_ip = "";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
in
{
  imports = [
    ./hardware-configuration.nix
    "${common.home-manager}/nixos"
  ] ++ (with nixos-hardware.nixosModules; [
    common-cpu-amd
    common-cpu-amd-pstate
    common-gpu-amd
    common-pc-ssd
  ]);

  inherit (common) zramSwap swapDevices;

  nix = common.nix // {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/jacobi/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  home-manager.users.jacobi = common.jacobi;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernel.sysctl = { } // common.sysctl_opts;
    tmp.useTmpfs = true;
  };

  environment = {
    systemPackages = with pkgs; [
      steam-run
    ];
    variables = {
      NIX_HOST = hostname;
      NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
    };
  };

  time.timeZone = common.timeZone;

  networking = {
    hostName = hostname;
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    firewall.enable = false;
  };

  users = {
    mutableUsers = false;
    users = {
      root.hashedPassword = "!";
      jacobi = {
        inherit (common) extraGroups;
        isNormalUser = true;
        hashedPasswordFile = "/etc/passwordFile-jacobi";
        openssh.authorizedKeys.keys = with common.pubkeys; [ charon mars ] ++ usual;
      };
    };
  };

  services = {
    k3s = {
      enable = false;
      role = "server";
      extraFlags = "--disable traefik --tls-san '${ts_ip}'";
    };
    libinput.enable = true;
    xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  } // common.services;
  virtualisation.docker.enable = true;

  hardware.pulseaudio.enable = false;
  networking.networkmanager.enable = true;

  programs.command-not-found.enable = false;
  programs.nix-ld.enable = true;
  security.sudo = common.security.sudo;
  system.stateVersion = "24.05";
}
