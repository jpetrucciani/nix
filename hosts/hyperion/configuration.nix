{ config, pkgs, ... }:
let
  common = import ../common.nix;
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./hardware-configuration.nix
  ];

  inherit (common) nix zramSwap;

  home-manager.users.jacobi = { pkgs, ... }: common.jacobi;

  # Use the systemd-boot EFI boot loader.
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
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${networking.hostName}/configuration.nix";
  };

  # Set your time zone.
  time.timeZone = "America/Indiana/Indianapolis";

  networking.hostName = "hyperion";
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

  users.mutableUsers = false;
  users.users.jacobi = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    passwordFile = "/etc/passwordFile-jacobi";

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO9u9+khlywG0vSsrTsdjZEhKlKBpXx8RnwESGw+zIKI galaxyboss"
    ];
  };

  # Disable password-based login for root.
  users.users.root.hashedPassword = "!";

  # List services that you want to enable:
  services = {
    openssh = {
      enable = true;
      passwordAuthentication = false;
    };
    tailscale.enable = true;
  };

  virtualisation.docker.enable = true;

  system.stateVersion = "21.11";

  swapDevices = [{ device = "/swapfile"; size = 1024; }];

  security.sudo.extraRules = [
    {
      users = [ "jacobi" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
