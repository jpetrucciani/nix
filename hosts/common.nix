{ pkgs
, flake
, machine-name
, isBarebones ? false
, ...
}:
let
  inherit (flake.inputs) home-manager nix-darwin;

  mms = import
    (fetchTarball {
      url = "https://github.com/mkaito/nixos-modded-minecraft-servers/archive/68f2066499c035fd81c9dacfea2f512d6b0b62e5.tar.gz";
      sha256 = "1nmw497ahb9hjjh0kwr1z782q41gcw5kw4dl4alg8pnyhgq141r1";
    });

  jacobi = import ../home.nix {
    inherit home-manager flake machine-name pkgs isBarebones;
  };
  constants = import ./constants.nix;
  inherit (constants) ports;
in
{
  inherit (constants) defaultLocale emails extraHosts extraLocaleSettings name nix ports pubkeys sysctl_opts timeZone;
  inherit home-manager jacobi nix-darwin mms pkgs;

  extraGroups = [ "wheel" "networkmanager" "docker" "podman" ];

  swapDevices = [{ device = "/swapfile"; size = 1024; }];

  security.sudo = {
    extraRules = [
      {
        users = [ "jacobi" ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
    extraConfig = ''
      Defaults env_keep+=NIX_HOST
      Defaults env_keep+=NIXOS_CONFIG
      Defaults env_keep+=NIXDARWIN_CONFIG
    '';
    wheelNeedsPassword = false;
  };

  _services = {
    blocky = {
      enable = true;
      # settings: https://0xerr0r.github.io/blocky/configuration
      settings = {
        blocking = {
          blackLists = {
            ads = [
              "http://sysctl.org/cameleon/hosts"
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
              "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
              "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
            ];
            special = [
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts"
            ];
          };
          blockTTL = "1m";
          blockType = "zeroIp";
          clientGroupsBlock = {
            default = [
              "ads"
              "special"
            ];
          };
          downloadAttempts = 5;
          downloadCooldown = "10s";
          downloadTimeout = "4m";
          refreshPeriod = "4h";
          startStrategy = "failOnError";
          whiteLists = {
            ads = [
            ];
          };
        };
        bootstrapDns = "tcp+udp:1.1.1.1";
        caching = {
          cacheTimeNegative = "30m";
          maxItemsCount = 0;
          maxTime = "30m";
          minTime = "5m";
          prefetchExpires = "2h";
          prefetchMaxItemsCount = 0;
          prefetchThreshold = 5;
          prefetching = true;
        };
        clientLookup = {
          clients = {
            luna = [
              "192.168.1.44"
            ];
          };
          singleNameOrder = [
            2
            1
          ];
        };
        conditional = {
          fallbackUpstream = false;
          mapping = { };
          rewrite = { };
        };
        connectIPVersion = "dual";
        customDNS = {
          customTTL = "1h";
          filterUnmappedTypes = true;
          mapping = {
            "cobi" = "192.168.1.44";
            "milkyway.cobi" = "192.168.1.40";
            "titan.cobi" = "192.168.1.41";
            "luna.cobi" = "192.168.1.44";
            "jupiter.cobi" = "192.168.1.69";
            "charon.cobi" = "192.168.1.71";
            "pluto.cobi" = "192.168.1.100";
            "phobos.cobi" = "192.168.1.134";
            "neptune.cobi" = "100.101.139.41";
          };
          rewrite = { };
        };
        ede = {
          enable = true;
        };
        filtering = {
          queryTypes = [
            "AAAA"
          ];
        };
        hostsFile = {
          filePath = "/etc/hosts";
          filterLoopback = true;
          hostsTTL = "60m";
          refreshPeriod = "30m";
        };
        httpPort = 4000;
        logFormat = "text";
        logLevel = "info";
        logPrivacy = false;
        logTimestamp = true;
        minTlsServeVersion = 1.3;
        port = 53;
        prometheus = {
          enable = true;
          path = "/metrics";
        };
        # queryLog = {
        # creationAttempts = 1;
        # creationCooldown = "2s";
        # logRetentionDays = 28;
        # target = "/var/log/blocky/";
        # type = "console";
        # };
        startVerifyUpstream = true;
        upstream = {
          default = [
            "1.1.1.1"
          ];
        };
        upstreamTimeout = "2s";
      };
    };
  };
  services = {
    tailscale.enable = true;
    # netdata.enable = true;
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = pkgs.lib.mkDefault "no";
        PasswordAuthentication = false;
        KexAlgorithms = [
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
        ];
        Ciphers = [
          "chacha20-poly1305@openssh.com"
          "aes256-gcm@openssh.com"
          "aes256-ctr"
        ];
        Macs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
          "umac-128-etm@openssh.com"
        ];
        X11Forwarding = true;
      };
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };

  minecraft = {
    conf = {
      jre8 = pkgs.temurin-bin-8;
      jre17 = pkgs.temurin-bin-17;
      jre18 = pkgs.temurin-bin-18;
      jre19 = pkgs.temurin-bin-19;

      jvmOpts = builtins.concatStringsSep " " [
        "-XX:+UseG1GC"
        "-XX:+ParallelRefProcEnabled"
        "-XX:MaxGCPauseMillis=200"
        "-XX:+UnlockExperimentalVMOptions"
        "-XX:+DisableExplicitGC"
        "-XX:+AlwaysPreTouch"
        "-XX:G1NewSizePercent=40"
        "-XX:G1MaxNewSizePercent=50"
        "-XX:G1HeapRegionSize=16M"
        "-XX:G1ReservePercent=15"
        "-XX:G1HeapWastePercent=5"
        "-XX:G1MixedGCCountTarget=4"
        "-XX:InitiatingHeapOccupancyPercent=20"
        "-XX:G1MixedGCLiveThresholdPercent=90"
        "-XX:G1RSetUpdatingPauseTimePercent=5"
        "-XX:SurvivorRatio=32"
        "-XX:+PerfDisableSharedMem"
        "-XX:MaxTenuringThreshold=1"
      ];

      defaults = {
        white-list = false;
        spawn-protection = 0;
        max-tick-time = 5 * 60 * 1000;
        allow-flight = true;
      };
    };
  };

  templates = {
    promtail =
      { hostname
      , loki_ip ? "100.78.40.10"
      , promtail_port ? ports.promtail
      , loki_port ? ports.loki
      , extra_scrape_configs ? [ ]
      }: {
        enable = true;
        configuration = {
          server = {
            http_listen_port = promtail_port;
            grpc_listen_port = 0;
          };
          positions = {
            filename = "/tmp/positions.yaml";
          };
          clients = [{
            url = "http://${loki_ip}:${toString loki_port}/loki/api/v1/push";
          }];
          scrape_configs = [{
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = hostname;
              };
            };
            relabel_configs = [{
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }];
          }] ++ extra_scrape_configs;
        };
      };
    promtail_scrapers = {
      caddy = { path ? "/var/log/caddy/*.log" }: {
        job_name = "caddy";
        static_configs = [{ targets = [ "localhost" ]; labels = { job = "caddylogs"; __path__ = path; }; }];
      };
    };
    prometheus_exporters = _: {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = ports.prometheus_node_exporter;
      };
    };
  };
}
