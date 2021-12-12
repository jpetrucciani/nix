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
  };

  environment.variables = {
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/titan/configuration.nix";
  };

  time.timeZone = common.timeZone;

  networking.hostName = "titan";
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

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

  services = { } // common.services;
  virtualisation.docker.enable = true;

  system.stateVersion = "21.11";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
