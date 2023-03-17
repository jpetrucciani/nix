{ config, pkgs, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption literalExpression mdDoc;
  inherit (lib.types) bool lines package path port str;
  cfg = config.services.zinc;
in
{
  imports = [ ];

  options.services.zinc = {
    enable = mkEnableOption "zinc";
    user = mkOption {
      type = str;
      default = "zinc";
      description = mdDoc "user account under which zinc runs";
    };
    group = mkOption {
      type = str;
      default = "zinc";
      description = mdDoc "group under which zinc runs";
    };
    dataDir = mkOption {
      type = path;
      default = "/var/lib/zinc";
      description = mdDoc ''the data directory for zinc'';
    };
    secretFile = mkOption {
      type = path;
      default = "/etc/default/zinc";
      description = mdDoc ''secret env variables for zinc'';
    };
    package = mkOption {
      default = pkgs.zinc;
      defaultText = literalExpression "pkgs.zinc";
      type = package;
      description = mdDoc ''zinc package to use'';
    };
    bindAddress = mkOption {
      type = str;
      default = "0.0.0.0";
      description = mdDoc ''zinc server IP address to bind to'';
    };
    bindPort = mkOption {
      type = port;
      default = 4080;
      description = mdDoc ''zinc server listen http port'';
    };
    prometheus = mkOption {
      type = bool;
      default = false;
      description = mdDoc ''Enables prometheus metrics on /metrics endpoint'';
    };
    telemetry = mkOption {
      type = bool;
      default = false;
      description = mdDoc ''send anonymous telemetry info for improving zinc'';
    };
    sentry = mkOption {
      type = bool;
      default = false;
      description = mdDoc ''send anonymous sentry info for improving zinc'';
    };
    sentryDSN = mkOption {
      type = str;
      default = "https://15b6d9b8be824b44896f32b0234c32b7@o1218932.ingest.sentry.io/6360942";
      description = mdDoc ''sentry DSN variable'';
    };
    debugMode = mkOption {
      type = bool;
      default = false;
      description = mdDoc ''run gin in debug mode'';
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
        ZINC_SERVER_ADDRESS = cfg.bindAddress;
        ZINC_SERVER_PORT = toString cfg.bindPort;
        ZINC_TELEMETRY = toString cfg.telemetry;
      };

      serviceConfig = {
        EnvironmentFile = cfg.secretFile;
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
