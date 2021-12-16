{ config, pkgs, ... }:
let
  common = import ../common.nix { inherit config pkgs; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./hardware-configuration.nix
  ];

  inherit (common) nix zramSwap swapDevices;

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
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/hyperion/configuration.nix";
  };

  time.timeZone = common.timeZone;

  networking.hostName = "neptune";
  networking.useDHCP = false;
  networking.interfaces.enp9s0.useDHCP = true;

  users.mutableUsers = false;
  users.users.jacobi = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    passwordFile = "/etc/passwordFile-jacobi";

    openssh.authorizedKeys.keys = [
      common.pubkeys.galaxyboss
      common.pubkeys.pluto
      common.pubkeys.hms
    ] ++ common.pubkeys.mobile;
  };

  # Disable password-based login for root.
  users.users.root.hashedPassword = "!";

  # List services that you want to enable:
  services = { } // common.services;

  virtualisation.docker.enable = true;

  system.stateVersion = "22.05";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
