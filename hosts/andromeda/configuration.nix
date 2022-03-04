{ config, pkgs, ... }:
let
  hostname = "andromeda";
  common = import ../common.nix { inherit config pkgs; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./hardware-configuration.nix
  ];

  inherit (common) nix zramSwap swapDevices;

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
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
  };

  time.timeZone = common.timeZone;

  networking.hostName = hostname;
  networking.useDHCP = false;
  networking.interfaces.enp0s10.useDHCP = true;

  users.users.root.hashedPassword = "!";
  users.mutableUsers = false;
  users.users.jacobi = {
    inherit (common) extraGroups;
    isNormalUser = true;
    passwordFile = "/etc/passwordFile-jacobi";

    openssh.authorizedKeys.keys = with common.pubkeys; [ m1max ];
  };

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services = {
    # Enable the X11 windowing system.
    xserver.enable = true;
    xserver.desktopManager.gnome.enable = true;
    # Enable touchpad support (enabled default in most desktopManager).
    xserver.libinput.enable = true;
  } // common.services;
  virtualisation.docker.enable = true;

  system.stateVersion = "22.05";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
