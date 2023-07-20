{ config, flake, machine-name, pkgs, lib, ... }:
let
  hostname = "edge";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./hardware-configuration.nix
    ../modules/conf/blackedge.nix
    ../modules/conf/ssh-remote-bind.nix
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

  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda";
        useOSProber = true;
      };
    };
    kernel.sysctl = { } // common.sysctl_opts;
    tmp.useTmpfs = true;
  };

  environment.variables = {
    NIX_HOST = hostname;
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
  };
  environment.etc."nixpkgs-path".source = common.pkgs.path;

  time.timeZone = common.timeZone;

  networking.hostName = hostname;
  networking.nameservers = [ "10.31.65.200" "1.1.1.1" ];
  networking.search = [ "blackedge.local" ];
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  networking.firewall.enable = false;

  users.users.root.hashedPassword = "!";
  users.mutableUsers = false;
  users.users.jacobi = {
    inherit (common) extraGroups;
    isNormalUser = true;
    passwordFile = "/etc/passwordFile-jacobi";
    openssh.authorizedKeys.keys = with common.pubkeys; [ edgewin hub2 ] ++ usual;
  };

  conf.blackedge.enable = true;

  services = {
    postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
      enableTCPIP = true;
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
        host all all 127.0.0.1/32 trust
        host all all ::1/128 trust
        host all all 100.64.0.0/10 trust
      '';
    };
    k3s = {
      enable = true;
      role = "server";
      extraFlags = "--disable traefik";
    };
    caddy =
      let
        internal_proxy = { port ? 10000, host ? "127.0.0.1" }: {
          extraConfig = ''
            import SECURITY
            tls /opt/crt/bec.crt /opt/crt/bec.key
            reverse_proxy /* {
              to ${host}:${toString port}
            }
          '';
        };
      in
      {
        extraConfig = ''
          (SECURITY) {
            encode zstd gzip
            header {
              -Server
              Strict-Transport-Security "max-age=31536000; include-subdomains;"
              X-XSS-Protection "1; mode=block"
              X-Frame-Options "DENY"
              X-Content-Type-Options nosniff
              Referrer-Policy  no-referrer-when-downgrade
              X-Robots-Tag "none"
            }
          }
        '';
        virtualHosts = {
          "bot.blackedge.capital" = internal_proxy { port = 8088; };
          "edge.blackedge.capital" = internal_proxy { };
          "vsc0.blackedge.capital" = internal_proxy { port = 8100; };
          "vsc1.blackedge.capital" = internal_proxy { port = 8101; };
        };
      };
  } // common.services;

  virtualisation.docker.enable = true;
  system.stateVersion = "22.11";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
