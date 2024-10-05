{ config, flake, machine-name, pkgs, ... }:
let
  inherit (flake.inputs) nixos-hardware;
  hostname = "proteus";
  ts_ip = "";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
in
{
  imports = [
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

  environment.variables = {
    NIX_HOST = hostname;
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
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
    xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
      # Enable touchpad support (enabled default in most desktopManager).
      libinput.enable = true;
    };
  } // common.services;
  virtualisation.docker.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  programs.nix-ld.enable = true;
  networking.networkmanager.enable = true;

  system.stateVersion = "24.05";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
