{ config, flake, machine-name, pkgs, lib, ... }:
let
  hostname = "terra";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./api.nix
    ./hardware-configuration.nix
    ../modules/servers/minifluxng.nix
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

  boot = {
    loader = {
      grub.enable = true;
      grub.device = "/dev/sda";
    };
    kernel.sysctl = { } // common.sysctl_opts;
    tmp.useTmpfs = true;
  };

  environment.variables = {
    NIX_HOST = hostname;
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
  };

  time.timeZone = common.timeZone;

  networking = {
    hostName = hostname;
    extraHosts = common.extraHosts.proxmox;
    useDHCP = false;
    interfaces.ens18 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "192.168.69.10";
        prefixLength = 24;
      }];
    };
    defaultGateway = "192.168.69.1";
    nameservers = [ "1.1.1.1" ];
    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedTCPPorts = with common.ports; usual;
      allowedUDPPorts = [ ];
      checkReversePath = "loose";
    };
  };

  age = {
    identityPaths = [ "/home/jacobi/.ssh/id_ed25519" ];
    secrets = {
      miniflux.file = ../../secrets/miniflux.age;
      vaultwarden.file = ../../secrets/vaultwarden.age;
      zitadel = {
        file = ../../secrets/zitadel.age;
        owner = "zitadel";
      };
    };
  };

  users = {
    mutableUsers = false;
    users = {
      root.hashedPassword = "!";
      jacobi = {
        inherit (common) extraGroups;
        isNormalUser = true;
        hashedPasswordFile = "/etc/passwordFile-jacobi";
        openssh.authorizedKeys.keys = with common.pubkeys; [ m1max ] ++ usual;
      };
    };
  };

  services = {
    caddy =
      let
        reverse_proxy = location: {
          extraConfig = ''
            import GEOBLOCK
            import SECURITY
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
        secure = block: {
          extraConfig = ''
            import SECURITY
            ${block}
          '';
        };
        secure_geo = block: secure ''
          import GEOBLOCK
          ${block}
        '';
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
            respond @tailscale "乃尺ㄩ卄" 403
          }

          (GEOBLOCK) {
            @geoblock {
              not maxmind_geolocation {
                db_path {env.GEOIP_DB}
                allow_countries US
              }
              not remote_ip 127.0.0.1 192.168.69.0/24 100.64.0.0/10
            }
            respond @geoblock "乃尺ㄩ卄" 403
          }

          (BA3GEOBLOCK) {
            @ba3geoblock {
              not maxmind_geolocation {
                db_path {env.GEOIP_DB}
                allow_countries US CA BD PH
              }
              not remote_ip 127.0.0.1
            }
            respond @ba3geoblock 403
          }

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
          "api.cobi.dev" = reverse_proxy "localhost:10000";
          "z.cobi.dev" = reverse_proxy "localhost:8080";
          "otf.cobi.dev" = reverse_proxy "localhost:8010";
          "auth.cobi.dev" = reverse_proxy neptune_traefik;
          "search.cobi.dev" = reverse_proxy neptune_traefik;
          "recipe.cobi.dev" = reverse_proxy orbit_traefik;
          "netdata.cobi.dev" = ts_reverse_proxy "localhost:${toString common.ports.netdata}";
          "flix.cobi.dev" = reverse_proxy "jupiter:${toString common.ports.plex}";
          "n8n.cobi.dev" = reverse_proxy "luna:${toString common.ports.n8n}";
          "ombi.cobi.dev" = reverse_proxy "neptune:5999";
          "rss.cobi.dev" = reverse_proxy "localhost:8099";
          "x.hexa.dev" = reverse_proxy "neptune:8421";
          "meme.x.hexa.dev" = reverse_proxy "neptune:8420";
          "edge.be.hexa.dev" = reverse_proxy "edge:10000";
          "vault.cobi.dev" = secure_geo ''
            reverse_proxy /* {
              to localhost:8222
            }
            reverse_proxy /notifications/hub {
              to localhost:3012
            }
          '';
          "cobi.dev" = secure ''
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
          "nix.cobi.dev" = secure ''
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
          "gemologic.dev" = secure ''
            route / {
              header +Content-Type "text/html; charset=utf-8"
              respond "${landing_page {}}"
            }
          '';
          "gemologic.cloud" = secure ''
            route / {
              header +Content-Type "text/html; charset=utf-8"
              respond "${landing_page {}}"
            }
          '';
          "broadsword.tech" = secure ''
            route / {
              header +Content-Type "text/html; charset=utf-8"
              respond "${landing_page {title = "broadsword";}}"
            }
          '';
          "vault.ba3digital.com" = {
            extraConfig = ''
              import BA3GEOBLOCK
              import SECURITY
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
      environmentFile = config.age.secrets.vaultwarden.path;
      config = {
        DOMAIN = "https://vault.cobi.dev";
        ENABLE_DB_WAL = false;
        SENDS_ALLOWED = true;
        SIGNUPS_ALLOWED = false;
        WEBSOCKET_ENABLED = true;
        ROCKET_ADDRESS = "0.0.0.0";
        ROCKET_PORT = 8222;
      };
    };
    promtail = common.templates.promtail {
      inherit hostname;
      extra_scrape_configs = [ (common.templates.promtail_scrapers.caddy { }) ];
    };
    prometheus.exporters = common.templates.prometheus_exporters { };
    minifluxng = {
      enable = true;
      baseUrl = "https://rss.cobi.dev/";
      dbHost = "jupiter";
      dbPort = 54321;
      envFilePath = config.age.secrets.miniflux.path;
      listenAddress = "127.0.0.1:8099";
    };
    lemmy = {
      enable = false;
      caddy.enable = true;
      database.createLocally = false;
      settings = {
        hostname = "hexa.dev";
        email = {
          smtp_server = "$SMTP_SERVER";
          smtp_login = "$SMTP_USERNAME";
          smtp_password = "$SMTP_PASSWORD";
          smtp_from_address = "jacobi@hexa.dev";
          tls_type = "tls";
        };
      };
    };
    k3s = {
      enable = true;
      role = "server";
      extraFlags = "--disable traefik";
    };
    zitadel = {
      enable = true;
      masterKeyFile = "/etc/default/zitadel";
      settings = {
        ExternalDomain = "z.cobi.dev";
        ExternalPort = 443;
      };
      extraSettingsPaths = [ config.age.secrets.zitadel.path ];
    };
  } // common.services;

  systemd.services.lemmy.serviceConfig.EnvironmentFile = "/etc/default/lemmy";
  systemd.services.lemmy.serviceConfig.ExecStartPre =
    let
      f = "/run/lemmy/config.hjson";
      settings = (pkgs.formats.json { }).generate "config.hjson" config.services.lemmy.settings;
    in
    lib.mkForce (pkgs.writers.writeBash "preLemmy" ''
      ${pkgs.envsubst}/bin/envsubst -i ${settings} -o ${f}
      chmod 0600 ${f}
    '');

  virtualisation.docker.enable = true;

  system.stateVersion = "23.11";
  security.sudo = common.security.sudo;
  security.acme = {
    acceptTerms = true;
    defaults.email = common.emails.personal;
  };
  programs.command-not-found.enable = false;
}
