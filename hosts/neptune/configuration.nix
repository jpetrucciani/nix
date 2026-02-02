{ config, flake, machine-name, pkgs, ... }:
let
  hostname = "neptune";
  ts_ip = "100.101.139.41";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./hardware-configuration.nix
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

  boot = {
    loader = {
      grub.enable = true;
      grub.device = "/dev/nvme0n1";
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
    useDHCP = false;
    interfaces.enp9s0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "142.132.149.106";
          prefixLength = 26;
        }
      ];
    };
    defaultGateway = "142.132.149.65";
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedTCPPorts = with common.ports; [
        80
        443
        # k3s?
        6443
      ] ++ usual;
      allowedUDPPorts = [ ];
      checkReversePath = "loose";
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
        openssh.authorizedKeys.keys = with common.pubkeys; [
          m1max
          nix-m1max
        ] ++ usual;
      };
    };
  };

  environment.systemPackages = [ pkgs.k3s ];

  services = {
    caddy = {
      enable = true;
      package = pkgs.zaddy;
      globalConfig = ''
        auto_https off
      '';
      extraConfig = ''
        :80 {
          reverse_proxy 127.0.0.1:8010
        }
        :443 {
          reverse_proxy 127.0.0.1:8443
        }
      '';
    };
    k3s = {
      enable = true;
      role = "server";
      extraFlags = "--disable traefik --tls-san '${ts_ip}'";
    };
    poglets = {
      enable = true;
      port = 8420;
      controlPort = 8421;
    };
    infinity.enable = true;
    ombi = {
      enable = true;
      port = 5999;
    };
    searx = {
      enable = false;
      configureUwsgi = true;
      uwsgiConfig = {
        http = "127.0.0.1:8069";
      };
      environmentFile = "/etc/default/searx";
      settings = {
        use_default_settings = {
          engines = {
            keep_only = [
              "github"
              "google"
              "stackexchange"
              "wikipedia"
            ];
          };
        };
        server = {
          port = 8069;
          bind_address = "127.0.0.1";
          secret_key = "@SEARX_SECRET_KEY@";
          default_http_headers = {
            X-Content-Type-Options = "nosniff";
            X-XSS-Protection = "1; mode=block";
            X-Download-Options = "noopen";
            X-Robots-Tag = "noindex, nofollow";
            Referrer-Policy = "no-referrer";
          };
        };
        ui = {
          autofocus = true;
        };
        general = {
          instance_name = "sadge";
        };
        engines = [
          {
            name = "google";
            engine = "google";
            shortcut = "go";
            use_mobile_ui = true;
            disabled = false;
          }
          {
            name = "google images";
            engine = "google_images";
            shortcut = "goi";
          }
          {
            name = "bing";
            engine = "bing";
            shortcut = "bi";
            disabled = true;
          }
          # {
          #   name = "stackoverflow";
          #   engine = "stackexchange";
          #   shortcut = "st";
          #   api_site = "stackoverflow";
          #   categories = "dev,stackoverflow";
          # }
          # {
          #   name = "askubuntu";
          #   engine = "stackexchange";
          #   shortcut = "ubuntu";
          #   api_site = "askubuntu";
          #   categories = "dev,stackoverflow";
          # }
          # {
          #   name = "superuser";
          #   engine = "stackexchange";
          #   shortcut = "su";
          #   api_site = "superuser";
          #   categories = "dev,stackoverflow";
          # }
          {
            name = "genius";
            engine = "genius";
            shortcut = "gen";
            categories = "music";
          }
          {
            name = "pypi";
            shortcut = "pip";
            engine = "xpath";
            paging = "True";
            search_url = "https://pypi.org/search?q={query}&page={pageno}";
            results_xpath = ''/html/body/main/div/div/div/form/div/ul/li/a[@class=" package-snippet "]'';
            url_xpath = "./@href";
            title_xpath = ''./h3/span[@class=" package-snippet__name "]'';
            content_xpath = "./p";
            suggestion_xpath = ''/html/body/main/div/div/div/form/div/div[@class=" callout-block "]/p/span/a[@class=" link "]'';
            first_page_num = "1";
            categories = "dev,python";
            about = {
              website = "https://pypi.org";
              wikidata_id = "Q2984686";
              official_api_documentation = "https://warehouse.readthedocs.io/api-reference/index.html";
              use_official_api = false;
              require_api_key = false;
              results = "HTML";
            };
          }
          {
            name = "nixpkgs";
            shortcut = "nix";
            engine = "elasticsearch";
            categories = "dev,nix";
            base_url = "https://nixos-search-5886075189.us-east-1.bonsaisearch.net:443";
            index = "latest-31-nixos-unstable";
            query_type = "match";
          }
          {
            name = "github";
            engine = "github";
            shortcut = "gh";
            categories = "dev";
          }
          {
            name = "duckduckgo";
            engine = "duckduckgo";
            shortcut = "ddg";
            disabled = true;
          }
        ];
        search = {
          safe_search = 0;
          autocomplete = "google";
        };
      };
    };
    promtail = common.templates.promtail { inherit hostname; };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_18;
      enableTCPIP = true;
      extensions = with pkgs.postgresql18Packages; [ pgvector ];
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
        host all all 127.0.0.1/32 trust
        host all all ::1/128 trust
        host all all 100.64.0.0/10 md5
        host all all 10.42.0.0/16 md5
      '';
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

  system.stateVersion = "23.11";
  security.sudo = common.security.sudo;
  security.acme = {
    acceptTerms = true;
    defaults.email = common.emails.personal;
  };
  programs.command-not-found.enable = false;
}
