{ pkgs, config, flake, machine-name, ... }:
let
  common = import ../common.nix { inherit config flake machine-name pkgs; };
in
{
  inherit (common) nix;

  boot.kernel.sysctl = { "net.ipv4.ip_forward" = 1; } // common.sysctl_opts;

  environment.systemPackages = with pkgs; [
    bashInteractive
    bash-completion
    coreutils-full
    curl
    figlet
    gawk
    gnugrep
    gnused
    gron
    jq
    just
    clolcat
    lsof
    moreutils
    nano
    nix
    ripgrep
    wget
    yq-go
  ];

  security.sudo = common.security.sudo;
  security.acme = {
    defaults = {
      email = common.emails.personal;
    };
    acceptTerms = true;
  };
  users.mutableUsers = false;
  users.extraUsers.jacobi = {
    createHome = true;
    isNormalUser = true;
    home = "/home/jacobi";
    description = "jacobi";
    group = "users";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    useDefaultShell = true;
    openssh.authorizedKeys.keys = with common.pubkeys; [ milkyway pluto ];
  };

  networking.firewall.enable = false;
  services = {
    inherit (common.services) openssh;
    tailscale.enable = true;
  };

  system.stateVersion = "24.11";
  programs.command-not-found.enable = false;
}
