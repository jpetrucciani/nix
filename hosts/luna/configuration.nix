{ config, flake, machine-name, pkgs, ... }:
let
  hostname = "luna";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    "${common.mms}/nixos/modules/services/games/minecraft-servers"
    ./hardware-configuration.nix
    ../modules/games/palworld.nix
    ../modules/games/stationeers.nix
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

  # Bootloader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };
    kernel.sysctl = { } // common.sysctl_opts;
    tmp.useTmpfs = true;
  };

  environment = {
    etc."nixpkgs-path".source = common.pkgs.path;
    variables = {
      NIX_HOST = hostname;
      NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
    };
  };

  time.timeZone = common.timeZone;

  networking = {
    hostName = hostname;
    # networkmanager.enable = true;
  };

  i18n.defaultLocale = common.defaultLocale;
  i18n.extraLocaleSettings = common.extraLocaleSettings;

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  users.users.jacobi = {
    isNormalUser = true;
    description = "jacobi";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      firefox
    ];
    openssh.authorizedKeys.keys = with common.pubkeys; [
      m1max
      nix-m1max
    ] ++ usual;
  };

  environment.systemPackages = [ ];

  networking.firewall.enable = false;
  services = {
    inherit (common._services) blocky;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    xserver = {
      enable = true;
      displayManager.lightdm.enable = true;
      desktopManager.xfce.enable = true;
      videoDrivers = [ "amdgpu" ];
      layout = "us";
      xkbVariant = "";
    };
    stationeers = {
      enable = false;
      worldName = "memeworld";
    };
    palworld = {
      enable = true;
      worldSettings.ServerPassword = "$PALWORLD_SERVER_PASSWORD";
    };
    modded-minecraft-servers = with common.minecraft; {
      eula = true;
      instances = {
        rlcraft = {
          inherit (conf) jvmOpts;
          enable = false;
          rsyncSSHKeys = [ common.pubkeys.pluto ];
          jvmPackage = conf.jre8;
          jvmInitialAllocation = "6G";
          jvmMaxAllocation = "8G";
          serverConfig =
            conf.defaults
              // {
              server-port = 25569;
              rcon-port = 25568;
              motd = "jacobi's rlcraft server";

              # rlcraft specific settings
              difficulty = 3;
              max-tick-time = -1;
              enable-command-block = true;
            };
        };
        vaulthunters = {
          inherit (conf) jvmOpts;
          enable = false;
          rsyncSSHKeys = [ common.pubkeys.pluto ];
          jvmPackage = conf.jre17;
          jvmInitialAllocation = "6G";
          jvmMaxAllocation = "8G";
          serverConfig =
            conf.defaults
              // {
              server-port = 25570;
              rcon-port = 25571;
              motd = "jacobi's vaulthunter server";
            };
        };
        vaulthunters-other = {
          inherit (conf) jvmOpts;
          enable = false;
          rsyncSSHKeys = [ common.pubkeys.pluto ];
          jvmPackage = conf.jre17;
          jvmInitialAllocation = "6G";
          jvmMaxAllocation = "8G";
          serverConfig =
            conf.defaults
              // {
              server-port = 25572;
              rcon-port = 25573;
              motd = "jacobi's other vaulthunter server";
            };
        };
      };
    };
    n8n = {
      enable = false;
    };
    step-ca =
      let
        base = "/var/lib/step-ca";
        certs = "${base}/certs";
        secrets = "${base}/secrets";
      in
      {
        enable = true;
        port = 443;
        address = "0.0.0.0";
        intermediatePasswordFile = "${secrets}/password";
        settings = {
          dnsNames = [ "cobi" ];
          root = "${certs}/root_ca.crt";
          crt = "${certs}/intermediate_ca.crt";
          key = "${secrets}/intermediate_ca_key";
          db = {
            type = "badger";
            dataSource = "${base}/db";
          };
          ssh = {
            hostKey = "${secrets}/ssh_host_ca_key";
            userKey = "${secrets}/ssh_user_ca_key";
          };
          logger = {
            format = "text";
          };
          claims = {
            minTLSCertDuration = "5m";
            maxTLSCertDuration = "90d";
            defaultTLSCertDuration = "24h";
          };
          authority = {
            provisioners = [
              {
                type = "ACME";
                name = "acme";
              }
              {
                type = "SSHPOP";
                name = "sshpop";
                claims = {
                  enableSSHCA = true;
                };
              }
            ];
          };
          tls = {
            cipherSuites = [
              "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
              "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
            ];
            minVersion = 1.2;
            maxVersion = 1.3;
            renegotiation = false;
          };
          templates = {
            ssh = {
              user = [
                {
                  name = "config.tpl";
                  type = "snippet";
                  template = "${base}/templates/ssh/config.tpl";
                  path = "~/.ssh/config";
                  comment = "#";
                }
                {
                  name = "step_includes.tpl";
                  type = "prepend-line";
                  template = "${base}/templates/ssh/step_includes.tpl";
                  path = ''''${STEPPATH}/ssh/includes'';
                  comment = "#";
                }
                {
                  name = "step_config.tpl";
                  type = "file";
                  template = "${base}/templates/ssh/step_config.tpl";
                  path = "ssh/config";
                  comment = "#";
                }
                {
                  name = "known_hosts.tpl";
                  type = "file";
                  template = "${base}/templates/ssh/known_hosts.tpl";
                  path = "ssh/known_hosts";
                  comment = "#";
                }
              ];
              host = [
                {
                  name = "sshd_config.tpl";
                  type = "snippet";
                  template = "${base}/templates/ssh/sshd_config.tpl";
                  path = "/etc/ssh/sshd_config";
                  comment = "#";
                  requires = [
                    "Certificate"
                    "Key"
                  ];
                }
                {
                  name = "ca.tpl";
                  type = "snippet";
                  template = "${base}/templates/ssh/ca.tpl";
                  path = "/etc/ssh/ca.pub";
                  comment = "#";
                }
              ];
            };
          };
        };
      };
    grafana = {
      enable = true;
      settings = {
        server = {
          http_port = common.ports.grafana;
          http_addr = "0.0.0.0";
        };
      };
      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://localhost:${toString common.ports.prometheus}";
            isDefault = true;
          }
          {
            name = "Loki";
            type = "loki";
            access = "proxy";
            url = "http://localhost:${toString common.ports.loki}";
          }
        ];
      };
    };
    loki = {
      enable = true;
      configuration = {
        server.http_listen_port = common.ports.loki;
        auth_enabled = false;

        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore = {
                store = "inmemory";
              };
              replication_factor = 1;
            };
          };
          chunk_idle_period = "1h";
          max_chunk_age = "1h";
          chunk_target_size = 999999;
          chunk_retain_period = "30s";
          max_transfer_retries = 0;
        };

        schema_config = {
          configs = [{
            from = "2022-06-06";
            store = "boltdb-shipper";
            object_store = "filesystem";
            schema = "v11";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }];
        };

        storage_config = {
          boltdb_shipper = {
            active_index_directory = "/var/lib/loki/boltdb-shipper-active";
            cache_location = "/var/lib/loki/boltdb-shipper-cache";
            cache_ttl = "24h";
            shared_store = "filesystem";
          };

          filesystem = {
            directory = "/var/lib/loki/chunks";
          };
        };

        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
        };

        chunk_store_config = {
          max_look_back_period = "0s";
        };

        table_manager = {
          retention_deletes_enabled = false;
          retention_period = "0s";
        };

        compactor = {
          working_directory = "/var/lib/loki";
          shared_store = "filesystem";
          compactor_ring = {
            kvstore = {
              store = "inmemory";
            };
          };
        };
      };
    };
    prometheus = {
      enable = true;
      port = common.ports.prometheus;
      scrapeConfigs =
        let
          hostScrape = host: {
            job_name = host;
            static_configs = [{
              targets = [ "${host}:${toString common.ports.prometheus_node_exporter}" ];
            }];
          };
        in
        [
          {
            job_name = "Loki service";
            static_configs = [{
              targets = [ "127.0.0.1:${toString common.ports.loki}" ];
            }];
          }
          {
            job_name = "luna";
            static_configs = [{
              targets = [ "127.0.0.1:${toString common.ports.prometheus_node_exporter}" ];
            }];
          }
          (hostScrape "bedrock")
          (hostScrape "phobos")
          (hostScrape "terra")
          (hostScrape "titan")
        ];
      exporters = common.templates.prometheus_exporters { };
    };
    promtail = common.templates.promtail { inherit hostname; loki_ip = "127.0.0.1"; };
  } // common.services;

  systemd.services.n8n.serviceConfig.EnvironmentFile = "/etc/default/n8n";

  virtualisation.docker.enable = true;
  virtualisation.oci-containers = {
    backend = "podman";
    containers.homeassistant = {
      volumes = [ "home-assistant:/config" ];
      environment.TZ = "US/Eastern";
      image = "ghcr.io/home-assistant/home-assistant:2024.1";
      extraOptions = [
        "--network=host"
      ];
    };
  };
  system.stateVersion = "23.11";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
