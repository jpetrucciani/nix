{ config, pkgs, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption literalExpression;
  inherit (lib.types) bool nullOr package path port str;
  cfg = config.services.zinc;
in
{
  imports = [ ];

  options.services.zinc = {
    enable = mkEnableOption "zinc";
    user = mkOption {
      type = str;
      default = "zinc";
      description = "user account under which zinc runs";
    };
    group = mkOption {
      type = str;
      default = "zinc";
      description = "group under which zinc runs";
    };
    dataDir = mkOption {
      type = path;
      default = "/var/lib/zinc";
      description = ''the data directory for zinc'';
    };
    secretFile = mkOption {
      type = nullOr path;
      default = "/etc/default/zinc";
      description = ''secret env variables for zinc'';
    };
    package = mkOption {
      default = pkgs.zinc;
      defaultText = literalExpression "pkgs.zinc";
      type = package;
      description = ''zinc package to use'';
    };
    address = mkOption {
      type = str;
      default = "0.0.0.0";
      description = ''zinc server IP address to bind to'';
    };
    port = mkOption {
      type = port;
      default = 4080;
      description = ''zinc server listen http port'';
    };
    prometheus = mkOption {
      type = bool;
      default = false;
      description = ''Enables prometheus metrics on /metrics endpoint'';
    };
    telemetry = mkOption {
      type = bool;
      default = false;
      description = ''send anonymous telemetry info for improving zinc'';
    };
    sentry = mkOption {
      type = bool;
      default = false;
      description = ''send anonymous sentry info for improving zinc'';
    };
    sentryDSN = mkOption {
      type = str;
      default = "https://15b6d9b8be824b44896f32b0234c32b7@o1218932.ingest.sentry.io/6360942";
      description = ''sentry DSN variable'';
    };
    debugMode = mkOption {
      type = bool;
      default = false;
      description = ''run gin in debug mode'';
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

    systemd.services.zinc = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      # env vars https://docs.zinc.dev/ZincSearch/environment-variables/
      environment = {
        HOME = cfg.dataDir;
        USER = cfg.user;
        GIN_MODE = if cfg.debugMode then "" else "release";
        ZINC_PROMETHEUS_ENABLE = toString cfg.prometheus;
        ZINC_SENTRY = toString cfg.sentry;
        ZINC_SENTRY_DSN = cfg.sentryDSN;
        ZINC_SERVER_ADDRESS = cfg.address;
        ZINC_SERVER_PORT = toString cfg.port;
        ZINC_TELEMETRY = toString cfg.telemetry;
      };

      serviceConfig = {
        ${if cfg.secretFile != null then "EnvironmentFile" else null} = "-${cfg.secretFile}";
        ExecStart = ''
          ${cfg.package}/bin/zinc
        '';
        Restart = "on-failure";
        StateDirectory = "zinc";
        User = cfg.user;
        WorkingDirectory = cfg.dataDir;
      };
    };
  };
}
