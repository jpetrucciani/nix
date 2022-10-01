{ config, pkgs, ... }:
let
  hostname = "neptune";
  common = import ../common.nix { inherit config pkgs; };
in
{
  imports = [
    "${common.home-manager.path}/nixos"
    ./hardware-configuration.nix
    ./api.nix
    ./charm.nix
    ../modules/servers/poglets.nix
  ];

  inherit (common) zramSwap;

  nix = common.nix // {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/jacobi/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  home-manager.users.jacobi = common.jacobi;
  nixpkgs.pkgs = common.pinned;

  boot = {
    loader = {
      grub.enable = true;
      grub.version = 2;
      grub.device = "/dev/nvme0n1";
    };
    kernel.sysctl = {
      "fs.inotify.max_user_watches" = "1048576";
      "fs.inotify.max_queued_events" = "1048576";
      "fs.inotify.max_user_instances" = "1048576";
    };
    tmpOnTmpfs = true;
  };

  environment.variables = {
    NIX_HOST = hostname;
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
  };

  time.timeZone = common.timeZone;

  networking.hostName = hostname;
  networking.useDHCP = false;
  networking.interfaces.enp9s0.useDHCP = true;
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedTCPPorts = with common.ports; [
      # k3s?
      6443
    ] ++ usual;
    allowedUDPPorts = [ ];
    checkReversePath = "loose";
  };

  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";
  users.users.jacobi = {
    inherit (common) extraGroups;
    isNormalUser = true;
    passwordFile = "/etc/passwordFile-jacobi";

    openssh.authorizedKeys.keys = with common.pubkeys; [
      m1max
    ] ++ usual;
  };

  environment.systemPackages = [ pkgs.k3s ];

  services = {
    k3s = {
      enable = true;
      role = "server";
      extraFlags = "--disable traefik";
    };
    caddy =
      let
        reverse_proxy = location: {
          extraConfig = ''
            import GEOBLOCK
            reverse_proxy /* {
              to ${location}
            }
          '';
        };
      in
      {
        enable = true;
        package = pkgs.xcaddy;
        email = common.emails.personal;

        # countries from here http://www.geonames.org/countries/
        extraConfig = ''
          (GEOBLOCK) {
            @geoblock {
              not maxmind_geolocation {
                db_path {env.GEOIP_DB}
                allow_countries US CA GM
              }
              not remote_ip 127.0.0.1
            }
            respond @geoblock 403
          }
        '';
        virtualHosts = {
          "api.cobi.dev" = reverse_proxy "localhost:10000";
          "auth.cobi.dev" = reverse_proxy "localhost:8088";
          "charm.cobi.dev" = reverse_proxy "localhost:35354";
          "home.cobi.dev" = reverse_proxy "home:${toString common.ports.home-assistant}";
          "netdata.cobi.dev" = reverse_proxy "localhost:${toString common.ports.netdata}";
          "flix.cobi.dev" = reverse_proxy "jupiter:${toString common.ports.plex}";
          "vault.cobi.dev" = {
            extraConfig = ''
              import GEOBLOCK
              reverse_proxy /* {
                to phobos:8222
              }
              reverse_proxy /notifications/hub {
                to phobos:3012
              }
            '';
          };
          "cobi.dev" = {
            extraConfig = ''
              route /static/* {
                s3proxy {
                  bucket "jacobi-static"
                  force_path_style
                }
              }
              route / {
                redir https://github.com/jpetrucciani/
              }
            '';
          };
          "nix.cobi.dev" = {
            extraConfig = ''
              route / {
                redir https://github.com/jpetrucciani/nix
              }
              route /up {
                redir https://raw.githubusercontent.com/jpetrucciani/nix/main/scripts/nixup.sh
              }
              route /os-up {
                redir https://github.com/samuela/nixos-up/archive/main.tar.gz
              }
            '';
          };
          "x.hexa.dev" = reverse_proxy "localhost:8421";
          "meme.x.hexa.dev" = reverse_proxy "localhost:8420";
        };
      };
    poglets = {
      enable = true;
      bindPort = 8420;
      controlPort = 8421;
    };
  } // common.services;

  # https://github.com/NixOS/nixpkgs/issues/103158
  systemd.services.k3s.after = [ "network-online.service" "firewall.service" ];
  systemd.services.k3s.serviceConfig.KillMode = pkgs.lib.mkForce "control-group";

  # https://github.com/NixOS/nixpkgs/issues/98766
  boot.kernelModules = [ "br_netfilter" "ip_conntrack" "ip_vs" "ip_vs_rr" "ip_vs_wrr" "ip_vs_sh" "overlay" ];
  networking.firewall.extraCommands = ''
    iptables -A INPUT -i cni+ -j ACCEPT
  '';

  virtualisation.docker.enable = true;

  system.stateVersion = "22.11";
  security.sudo = common.security.sudo;
  security.acme = {
    acceptTerms = true;
    defaults.email = common.emails.personal;
  };
  programs.command-not-found.enable = false;
}
