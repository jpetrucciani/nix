{ config, pkgs, ... }:
let
  common = import ../common.nix { inherit config pkgs; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./hardware-configuration.nix
  ];

  inherit (common) nix zramSwap;

  home-manager.users.jacobi = { pkgs, ... }: common.jacobi;
  nixpkgs.pkgs = common.pinned;

  boot = {
    loader = {
      grub.enable = true;
      grub.version = 2;
      grub.device = "/dev/nvme0n1";
    };
    kernel.sysctl = {
      "fs.inotify.max_user_watches" = "1048576";
    };
  };

  environment.variables = {
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/neptune/configuration.nix";
  };

  time.timeZone = common.timeZone;

  networking.hostName = "neptune";
  networking.useDHCP = false;
  networking.interfaces.enp9s0.useDHCP = true;
  networking.firewall.enable = false;

  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";
  users.users.jacobi = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    passwordFile = "/etc/passwordFile-jacobi";

    openssh.authorizedKeys.keys = with common.pubkeys; [
      galaxyboss
      pluto
      hms
    ] ++ common.pubkeys.mobile;
  };

  environment.systemPackages = [ pkgs.k3s ];
  services = {
    k3s = {
      enable = true;
      role = "server";
    };
  } // common.services;
  virtualisation.docker.enable = true;
  system.stateVersion = "22.05";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
