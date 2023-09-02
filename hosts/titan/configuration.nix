{ config, flake, machine-name, pkgs, ... }:
let
  inherit (flake.inputs) nixos-hardware;
  hostname = "titan";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./hardware-configuration.nix
  ] ++ (with nixos-hardware.nixosModules; [
    common-gpu-nvidia
    common-cpu-amd
  ]);

  inherit (common) zramSwap swapDevices;

  nix = common.nix-cuda // {
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

  networking.hostName = hostname;
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  networking.firewall.enable = false;

  users.users.root.hashedPassword = "!";
  users.mutableUsers = false;
  users.users.jacobi = {
    inherit (common) extraGroups;
    isNormalUser = true;
    passwordFile = "/etc/passwordFile-jacobi";
    openssh.authorizedKeys.keys = with common.pubkeys; [ ] ++ usual;
  };

  services = {
    promtail = common.templates.promtail { inherit hostname; };
    prometheus.exporters = common.templates.prometheus_exporters { };
  } // common.services;

  system.stateVersion = "23.11";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;

  # nvidia setup?
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
  };
  hardware.opengl.enable = true;
  hardware.opengl.driSupport32Bit = true;
}
