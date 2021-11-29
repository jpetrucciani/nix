{ config, pkgs, ... }:

let
  home-manager = fetchTarball "https://github.com/nix-community/home-manager/archive/release-21.11.tar.gz";
  jacobi = import /home/jacobi/cfg/home.nix;
in
{
#  home-manager.users.jacobi = { pkgs, ... }: {
#    home.packages = with pkgs; [];
#    programs.starship.enable = true;
#  };

  home-manager.users.jacobi = { pkgs, ... }: jacobi;

  imports = [
    "${home-manager}/nixos"
    ./hardware-configuration.nix
  ];

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

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      max-jobs = auto
      extra-experimental-features = nix-command flakes
    '';
  };

  environment.variables = {
    IS_NIXOS = "true";
  };

  # Set your time zone.
  time.timeZone = "America/Indiana/Indianapolis";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  networking.hostName = "hyperion";

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
  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };
}
