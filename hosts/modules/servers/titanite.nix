{ config, lib, pkgs, ... }:
let
  inherit (lib) literalExpression mkEnableOption mkIf mkOption;
  inherit (lib.types) attrs listOf nullOr package path port str;

  cfg = config.services.titanite;
  settingsFormat = pkgs.formats.toml { };

  configFile =
    if cfg.configFile != null then
      cfg.configFile
    else
      settingsFormat.generate "titanite.toml" cfg.settings;

  execArgs = [
    "${cfg.package}/bin/titanite"
    "serve"
    "--config"
    (toString configFile)
  ] ++ cfg.extraArgs;

  checkArgs = [
    "${cfg.package}/bin/titanite"
    "check"
    "--config"
    (toString configFile)
  ];
in
{
  imports = [ ];

  options.services.titanite = {
    enable = mkEnableOption "Titanite DNS resolver";

    package = mkOption {
      type = package;
      default = pkgs.titanite;
      defaultText = literalExpression "pkgs.titanite";
      description = "Titanite package to use.";
    };

    user = mkOption {
      type = str;
      default = "titanite";
      description = "User account under which Titanite runs.";
    };

    group = mkOption {
      type = str;
      default = "titanite";
      description = "Group under which Titanite runs.";
    };

    dataDir = mkOption {
      type = path;
      default = "/var/lib/titanite";
      description = "Titanite state directory.";
    };

    logDir = mkOption {
      type = path;
      default = "/var/log/titanite";
      description = "Titanite log directory.";
    };

    configFile = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        Path to an existing Titanite TOML config. When this is set, settings is
        ignored.
      '';
      example = "/etc/titanite/titanite.homelab.toml";
    };

    settings = mkOption {
      inherit (settingsFormat) type;
      default = {
        listen_udp = "0.0.0.0:5353";
        listen_tcp = "0.0.0.0:5353";
        upstream_timeout_ms = 2000;
        upstreams = [
          {
            address = "1.1.1.1:53";
            priority = 0;
          }
          {
            address = "1.0.0.1:53";
            priority = 10;
          }
        ];
        forward_zones = [ ];
        observe = {
          metrics.listen = "127.0.0.1:9191";
          logging.structured = false;
          passive_dns = {
            enabled = false;
            path = "/var/log/titanite/passive.jsonl";
            deduplicate_window = "1h";
            retention = "30d";
            anonymize_client_ip = true;
          };
        };
        zones = [ ];
        plugins = [ ];
      };
      description = ''
        Titanite TOML settings. This is rendered to a generated config file
        unless configFile is set. Use upstreams for the default recursive pool
        and forward_zones for suffix-specific internal resolvers.
      '';
      example = literalExpression ''
        {
          listen_udp = "0.0.0.0:53";
          listen_tcp = "0.0.0.0:53";
          upstream_timeout_ms = 2000;
          upstreams = [
            {
              address = "1.1.1.1:53";
              priority = 0;
            }
            {
              address = "1.0.0.1:53";
              priority = 10;
            }
          ];
          forward_zones = [
            {
              name = "ad.home.arpa";
              upstream = "192.168.1.10:53";
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
          zones = [
            {
              name = "home.arpa";
              records = [
                {
                  name = "router.home.arpa";
                  type = "A";
                  value = "192.168.1.1";
                  ttl = 300;
                }
              ];
            }
          ];
          plugins = [ ];
        }
      '';
    };

    extraArgs = mkOption {
      type = listOf str;
      default = [ ];
      description = "Additional arguments passed to titanite serve.";
    };

    openFirewall = mkEnableOption "firewall rules for Titanite DNS listeners";

    firewall = {
      allowedTCPPorts = mkOption {
        type = listOf port;
        default = [ 5353 ];
        description = "TCP ports to open when openFirewall is enabled.";
      };

      allowedUDPPorts = mkOption {
        type = listOf port;
        default = [ 5353 ];
        description = "UDP ports to open when openFirewall is enabled.";
      };
    };

    extraReadWritePaths = mkOption {
      type = listOf path;
      default = [ ];
      description = ''
        Additional paths Titanite may write to under the systemd sandbox.
      '';
    };

    serviceConfig = mkOption {
      type = attrs;
      default = { };
      description = "Extra systemd serviceConfig settings for titanite.service.";
      example = literalExpression ''
        {
          RestartSec = 5;
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      inherit (cfg) group;
      home = cfg.dataDir;
      createHome = true;
      isSystemUser = true;
    };
    users.groups.${cfg.group} = { };

    systemd.tmpfiles.rules = [
      "d ${toString cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.logDir} 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.titanite = {
      description = "Titanite DNS resolver";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      environment.TITANITE_CONFIG = toString configFile;

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStartPre = lib.escapeShellArgs checkArgs;
        ExecStart = lib.escapeShellArgs execArgs;
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "on-failure";
        RestartSec = 2;

        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        NoNewPrivileges = true;

        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        ReadOnlyPaths = [ "-/etc/titanite" ];
        ReadWritePaths = [
          cfg.dataDir
          cfg.logDir
        ] ++ cfg.extraReadWritePaths;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";

        StandardOutput = "journal";
        StandardError = "journal";
      } // cfg.serviceConfig;
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = cfg.firewall.allowedTCPPorts;
      allowedUDPPorts = cfg.firewall.allowedUDPPorts;
    };
  };
}
