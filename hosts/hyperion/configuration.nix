{ config, pkgs, ... }:
let
  hostname = "hyperion";
  common = import ../common.nix { inherit config pkgs; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./hardware-configuration.nix
  ];

  inherit (common) zramSwap swapDevices;

  nix = common.nix // {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/jacobi/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  home-manager.users.jacobi = common.jacobi;
  nixpkgs.pkgs = common.pinned;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernel.sysctl = {
      "fs.inotify.max_user_watches" = "1048576";
    };
    tmpOnTmpfs = true;
  };

  environment.variables = {
    NIX_HOST = hostname;
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
  };

  time.timeZone = common.timeZone;

  networking.hostName = hostname;
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

  users.users.root.hashedPassword = "!";
  users.mutableUsers = false;
  users.users.jacobi = {
    inherit (common) extraGroups;
    isNormalUser = true;
    passwordFile = "/etc/passwordFile-jacobi";

    openssh.authorizedKeys.keys = with common.pubkeys; [ charon ] ++ usual;
  };

  services = { } // common.services;
  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;
  };

  system.stateVersion = "22.05";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
