{ config, flake, machine-name, pkgs, ... }:
let
  hostname = "cy1-nix-01";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
  ts_ip = common.hostRecords.tailnet.${hostname};
  hermesRegistry = pkgs.writeText "hermes-agent-registry.json" (builtins.toJSON {
    version = 2;
    flakes = [
      {
        exact = true;
        from = { type = "indirect"; id = "nixpkgs"; };
        to = { type = "path"; path = toString pkgs.path; };
      }
    ] ++ pkgs.lib.mapAttrsToList
      (id: registry: {
        exact = true;
        from = { type = "indirect"; inherit id; };
        inherit (registry) to;
      })
      common.nix-be.registry;
  });
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./hardware-configuration.nix
    ../modules/conf/blackedge.nix
    ../modules/servers/hermes-agent.nix
    ../modules/servers/titanite.nix
  ];

  inherit (common) zramSwap swapDevices;

  nix = common.nix-be // {
    package = pkgs._nix;
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/jacobi/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  home-manager.users.jacobi = common.jacobi;

  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      systemd-boot = {
        enable = true;
        configurationLimit = 3;
      };
    };
    kernel.sysctl = { } // common.sysctl_opts;
    tmp.useTmpfs = true;
    supportedFilesystems = [ "nfs" ];
  };

  environment = {
    variables = {
      NIX_HOST = hostname;
      NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
    };
    etc = {
      "nixpkgs-path".source = common.pkgs.path;
    };
    systemPackages = with pkgs; [
      amazon-ecr-credential-helper
      cifs-utils
      nfs-utils
    ];
  };

  time.timeZone = common.tz.work;

  networking = {
    hostName = hostname;
    nameservers = [ ts_ip ];
    search = [ "blackedge.local" ];
    useDHCP = false;
    interfaces.ens2f0np0.useDHCP = true;
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
        openssh.authorizedKeys.keys = with common.pubkeys; [ edge ] ++ usual;
      };
    };
  };

  conf.blackedge = {
    enable = true;
    allowedGroups = [ "systems" ];
  };

  services = {
    cron.enable = true;
    hermes-agent = {
      enable = true;
      instances.goblin = {
        uid = 32001;
        packages = with pkgs; [
          config.nix.package
          aq
          curl
          fd
          gh
          git
          glab
          jq
          nano
          openssh
          ripgrep
          uv
          yq-go
        ];
        environment = {
          NIX_REMOTE = "daemon";
          NIX_PATH = "nixpkgs=${pkgs.path}";
          NIX_CONFIG = ''
            experimental-features = nix-command flakes
            flake-registry = ${hermesRegistry}
          '';
          NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        };
        mounts = {
          "/nix/store".source = "/nix/store";
          "/nix/var/nix/daemon-socket".source = "/nix/var/nix/daemon-socket";
        };
        settings = {
          terminal = {
            backend = "local";
            cwd = "/var/lib/hermes/home";
          };
          agent.disabled_toolsets = [ "tts" ];
          stt.enabled = false;
          voice.auto_tts = false;
          mcp_servers = {
            grafana = {
              command = "${pkgs.uv}/bin/uvx";
              args = [ "mcp-grafana" "--disable-write" ];
            };
            netbox.command = "${pkgs.uv}/bin/uvx";
          };
          platforms.slack.extra = {
            unauthorized_dm_behavior = "ignore";
            require_mention = true;
            allow_bots = "none";
          };
        };
      };
    };
    logind.settings.Login = {
      RuntimeDirectorySize = "24G";
    };
    resolved = {
      enable = true;
      settings.Resolve = {
        FallbackDNS = [ ts_ip ];
        Domains = [ "blackedge.local" "~." ];
        LLMNR = false;
        MulticastDNS = false;
        ResolveUnicastSingleLabel = false;
      };
    };
    rpcbind.enable = true;
    _3proxy = {
      enable = true;
      services = [{
        type = "socks";
        auth = [ "none" ];
        maxConnections = 200;
      }];
    };
    titanite = {
      enable = true;
      settings = {
        listen_udp = "${ts_ip}:53";
        listen_tcp = "${ts_ip}:53";
        upstream_timeout_ms = 500;
        upstreams = [
          {
            address = "1.1.1.1:53";
            priority = 0;
            timeout_ms = 500;
          }
          {
            address = "1.0.0.1:53";
            priority = 0;
            timeout_ms = 500;
          }
        ];
        forward_zones = [
          {
            name = "blackedge.local";
            upstream = "10.31.155.10:53";
          }
        ];
        observe = {
          metrics.listen = "127.0.0.1:9191";
          logging.structured = true;
          passive_dns = {
            enabled = false;
            path = "/var/log/titanite/passive.jsonl";
            deduplicate_window = "1h";
            retention = "30d";
            anonymize_client_ip = true;
          };
        };
        zones =
          let
            record = name: value: { inherit name value; type = "A"; ttl = 300; };
            zone = name: value: {
              inherit name;
              records = [ (record name value) ];
            };
          in
          (pkgs.lib.mapAttrsToList zone common.hostRecords.tailnet)
            ++ [
            {
              name = "x";
              records = [ (record "meme.x" ts_ip) ];
            }
          ];
        plugins = [
          {
            name = "toys";
            type = "toys";
            zone = "toy";
            enabled_toys = [ "ip" "time" "cidr" "uuid" "rand" "epoch" "hash" "health" "stats" "version" ];
            priority = -1;
            fail_open = true;
            timeout = "50ms";
          }
        ];
      };
    };
  } // common.services;

  fileSystems."/mnt/win" = {
    device = "//aur-jpetrucciani-01.blackedge.local/c$/mnt";
    fsType = "cifs";
    options =
      let
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      in
      [ "${automount_opts},credentials=/etc/default/smb-secrets,uid=1000,gid=100" ];
  };

  virtualisation.docker.enable = true;
  systemd.services.podman-hermes-agent-goblin = {
    wants = [ "nix-daemon.socket" ];
    after = [ "nix-daemon.socket" ];
    unitConfig.RequiresMountsFor = [ "/nix/store" ];
  };
  system.stateVersion = "26.05";
  security.sudo = common.security.sudo;
  programs = {
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        libcap
        xz
        openssl
        zlib
      ];
    };
  };
  security.pam.loginLimits = [
    { domain = "*"; item = "nofile"; type = "-"; value = "131072"; }
  ];
}
