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

  environment = {
    variables = {
      NIX_HOST = hostname;
      NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
    };
    etc."nixpkgs-path".source = common.pkgs.path;
    systemPackages = with pkgs; [
      amazon-ecr-credential-helper
    ];
  };

  time.timeZone = common.tz.work;

  networking = {
    hostName = hostname;
    nameservers = [ "10.31.65.200" "1.1.1.1" ];
    search = [ "blackedge.local" ];
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    firewall.enable = false;
  };

  users = {
    mutableUsers = false;
    users = {
      root.hashedPassword = "!";
      jacobi = {
        inherit (common) extraGroups;
        isNormalUser = true;
        hashedPasswordFile = "/etc/passwordFile-jacobi";
        openssh.authorizedKeys.keys = with common.pubkeys; [ edgewin hub2 ] ++ usual;
      };
    };
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
    k3s =
      let
        oidc_flags = builtins.concatStringsSep " " [
          "--kube-apiserver-arg=oidc-issuer-url=https://accounts.google.com"
          "--kube-apiserver-arg=oidc-client-id=356820992289-89b30uojlrkqkm79g6hb0216d7j9ru9s.apps.googleusercontent.com"
          "--kube-apiserver-arg=oidc-username-claim=email"
          "--kube-apiserver-arg=oidc-groups-claim=groups"
        ];
      in
      {
        enable = true;
        role = "server";
        extraFlags = "--disable traefik ${oidc_flags}";
      };
    caddy =
      let
        internal_proxy = { port ? 10000, host ? "127.0.0.1" }: {
          extraConfig = ''
            tls /opt/crt/bec.crt /opt/crt/bec.key
            reverse_proxy /* {
              to ${host}:${toString port}
            }
          '';
        };
      in
      {
        enable = true;
        package = pkgs.zaddy;
        email = common.emails.personal;
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
          "influx.blackedge.capital" = internal_proxy { host = "aur-devopsdb"; port = 8086; };
        };
      };
  } // common.services;

  virtualisation.docker.enable = true;
  system.stateVersion = "23.11";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
