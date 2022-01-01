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
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernel.sysctl = {
      "fs.inotify.max_user_watches" = "1048576";
    };
    tmpOnTmpfs = true;
  };

  environment.variables = {
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/titan/configuration.nix";
  };

  time.timeZone = common.timeZone;

  networking.hostName = "titan";
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

  users.users.root.hashedPassword = "!";
  users.mutableUsers = false;
  users.users.jacobi = {
    isNormalUser = true;
    extraGroups = common.extraGroups;
    passwordFile = "/etc/passwordFile-jacobi";

    openssh.authorizedKeys.keys = [ ] ++ common.pubkeys.common;
  };

  services = { } // common.services;
  virtualisation.docker.enable = true;

  system.stateVersion = "22.05";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
