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
  networking.extraHosts = common.extraHosts.proxmox;
  networking.useDHCP = false;
  networking.interfaces.ens18.useDHCP = false;
  networking.interfaces.ens18.ipv4.addresses = [{
    address = "192.168.69.10";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.69.1";
  networking.nameservers = [ "1.1.1.1" ];
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedTCPPorts = with common.ports; [ ] ++ usual;
    allowedUDPPorts = [ ];
    checkReversePath = "loose";
  };

  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";
  users.users.jacobi = {
    inherit (common) extraGroups;
    isNormalUser = true;
    passwordFile = "/etc/passwordFile-jacobi";

    openssh.authorizedKeys.keys = with common.pubkeys; [ m1max ] ++ usual;
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
        ts_reverse_proxy = location: {
          extraConfig = ''
            import TAILSCALE
            reverse_proxy /* {
              to ${location}
            }
          '';
        };
        landing_page = { title ? "gemologic", start ? "#000", end ? "#6A3DE8" }:
          ''<html style='background-image: linear-gradient(to bottom right, ${start}, ${end});height:100%'><head><title>${title}</title></head></html>'';
        neptune_traefik = "neptune:8088";
        orbit_traefik = "${ip.orbit}:8088";
        ip = {
          ba3 = "192.168.69.20";
          orbit = "192.168.69.42";
          bedrock = "192.168.69.70";
        };
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
          (TAILSCALE) {
            @tailscale not remote_ip 127.0.0.1 100.64.0.0/10
            respond @tailscale "Kek" 403
          }

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

          (BA3GEOBLOCK) {
            @ba3geoblock {
              not maxmind_geolocation {
                db_path {env.GEOIP_DB}
                allow_countries US CA BD
              }
              not remote_ip 127.0.0.1
            }
            respond @ba3geoblock 403
          }
        '';
        virtualHosts = {
          "api.cobi.dev" = reverse_proxy "neptune:10000";
          "auth.cobi.dev" = reverse_proxy neptune_traefik;
          "search.cobi.dev" = reverse_proxy neptune_traefik;
          "recipe.cobi.dev" = reverse_proxy orbit_traefik;
          "netdata.cobi.dev" = ts_reverse_proxy "localhost:${toString common.ports.netdata}";
          "flix.cobi.dev" = reverse_proxy "jupiter:${toString common.ports.plex}";
          "n8n.cobi.dev" = reverse_proxy "luna:${toString common.ports.n8n}";
          "ombi.cobi.dev" = reverse_proxy "neptune:5999";
          "x.hexa.dev" = reverse_proxy "neptune:8421";
          "meme.x.hexa.dev" = reverse_proxy "neptune:8420";
          "vault.cobi.dev" = {
            extraConfig = ''
              import GEOBLOCK
              reverse_proxy /* {
                to localhost:8222
              }
              reverse_proxy /notifications/hub {
                to localhost:3012
              }
            '';
          };
          "cobi.dev" = {
            extraConfig = ''
              route /static/* {
                s3proxy {
                  bucket "jacobi-static"
                  endpoint "https://s3.wasabisys.com"
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
              route /latest {
                redir https://github.com/jpetrucciani/nix/archive/main.tar.gz
              }
              handle_path /x/* {
                redir https://github.com/jpetrucciani/nix/archive/{path.0}.tar.gz
              }
              handle_path /p/* {
                hax {
                  enable_tarball
                  tarball_file_name "default.nix"
                  tarball_file_text "\{j?import(fetchTarball\{url=\"https://nix.cobi.dev/latest\";\})\{\}\}:with j;{path.0}"
                }
              }
              route /up {
                redir https://raw.githubusercontent.com/jpetrucciani/nix/main/scripts/nixup.sh
              }
              route /os-up {
                redir https://github.com/samuela/nixos-up/archive/main.tar.gz
              }
            '';
          };
          "gemologic.dev" = {
            extraConfig = ''
              route / {
                header +Content-Type "text/html; charset=utf-8"
                respond "${landing_page {}}"
              }
            '';
          };
          "gemologic.cloud" = {
            extraConfig = ''
              route / {
                header +Content-Type "text/html; charset=utf-8"
                respond "${landing_page {}}"
              }
            '';
          };
          "broadsword.tech" = {
            extraConfig = ''
              route / {
                header +Content-Type "text/html; charset=utf-8"
                respond "${landing_page {title = "broadsword";}}"
              }
            '';
          };
          "vault.ba3digital.com" = {
            extraConfig = ''
              import BA3GEOBLOCK
              reverse_proxy /* {
                to ${ip.ba3}:8222
              }
              reverse_proxy /notifications/hub {
                to ${ip.ba3}:3012
              }
            '';
          };
        };
      };
    vaultwarden = {
      enable = true;
      dbBackend = "postgresql";
      environmentFile = "/etc/default/vaultwarden";
      config = {
        domain = "https://vault.cobi.dev";
        enableDbWal = "false";
        signupsAllowed = false;
        websocketEnabled = true;
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
