{ config, pkgs, ... }:
let
  hostname = "terra";
  common = import ../common.nix { inherit config pkgs; };
in
{
  imports = [
    "${common.home-manager.path}/nixos"
    ./hardware-configuration.nix
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
      grub.device = "/dev/sda";
    };
    kernel.sysctl = { } // common.sysctl_opts;
    tmpOnTmpfs = true;
  };

  environment.variables = {
    NIX_HOST = hostname;
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
  };

  time.timeZone = common.timeZone;

  networking.hostName = hostname;
  networking.useDHCP = false;
  networking.interfaces.ens18.useDHCP = false;
  networking.interfaces.ens18.ipv4.addresses = [{
    address = "192.168.69.10";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.69.1";
  networking.nameservers = [ "1.1.1.1" ];
  networking.firewall.enable = false;

  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";
  users.users.jacobi = {
    inherit (common) extraGroups;
    isNormalUser = true;
    passwordFile = "/etc/passwordFile-jacobi";

    openssh.authorizedKeys.keys = with common.pubkeys; [ ] ++ usual;
  };

  services = {
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
        landing_page = ''<html style='background-image: linear-gradient(to bottom right, #000, #6A3DE8);height:100%'></html>'';
        traefik = "localhost:8088";
      in
      {
        enable = true;
        package = pkgs.zaddy;
        email = common.emails.personal;

        globalConfig = ''
          order hax after handle_path
        '';

        # countries from here http://www.geonames.org/countries/
        extraConfig = ''
          (GEOBLOCK) {
            @geoblock {
              not maxmind_geolocation {
                db_path {env.GEOIP_DB}
                allow_countries US
              }
              not remote_ip 127.0.0.1
            }
            respond @geoblock 403
          }
        '';
        virtualHosts = {
          "gemologic.dev" = {
            extraConfig = ''
              route / {
                header +Content-Type "text/html; charset=utf-8"
                respond "${landing_page}"
              }
            '';
          };
          "gemologic.cloud" = {
            extraConfig = ''
              route / {
                header +Content-Type "text/html; charset=utf-8"
                respond "${landing_page}"
              }
            '';
          };
          "vault.ba3digital.com" = {
            extraConfig = ''
              import GEOBLOCK
              reverse_proxy /* {
                to 192.168.69.20:8222
              }
              reverse_proxy /notifications/hub {
                to 192.168.69.20:3012
              }
            '';
          };
        };
      };
  } // common.services;

  virtualisation.docker.enable = true;

  system.stateVersion = "22.11";
  security.sudo = common.security.sudo;
  security.acme = {
    acceptTerms = true;
    defaults.email = common.emails.personal;
  };
  programs.command-not-found.enable = false;
}
