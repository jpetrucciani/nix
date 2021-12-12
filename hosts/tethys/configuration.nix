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
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/tethys/configuration.nix";
  };

  time.timeZone = common.timeZone;

  networking.hostName = "tethys";
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

  # List services that you want to enable:
  services = {
    openssh = {
      enable = true;
      passwordAuthentication = false;
      permitRootLogin = "no";
      forwardX11 = true;
    };
  } // common.services;

  virtualisation.docker.enable = true;

  system.stateVersion = "21.11";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
