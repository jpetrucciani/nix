{ config, pkgs, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption literalExpression;
  inherit (lib.types) nullOr package path port str;
  cfg = config.services.questdb;
in
{
  imports = [ ];

  options.services.questdb = {
    enable = mkEnableOption "questdb";
    user = mkOption {
      type = str;
      default = "questdb";
      description = "user account under which questdb runs";
    };
    group = mkOption {
      type = str;
      default = "questdb";
      description = "group under which questdb runs";
    };
    dataDir = mkOption {
      type = path;
      default = "/var/lib/questdb";
      description = ''the data directory for questdb'';
    };
    package = mkOption {
      default = pkgs.questdb;
      defaultText = literalExpression "pkgs.questdb";
      type = package;
      description = ''questdb package to use'';
    };
    httpAddress = mkOption {
      type = str;
      default = "0.0.0.0";
      description = ''questdb server IP address to bind to for the http server. see https://questdb.io/docs/configuration/#http-server'';
    };
    httpPort = mkOption {
      type = port;
      default = 9000;
      description = ''questdb server listen http port'';
    };
    pgAddress = mkOption {
      type = str;
      default = "0.0.0.0";
      description = ''questdb server IP address to bind to for the pg server. see https://questdb.io/docs/configuration/#postgres-wire-protocol'';
    };
    pgPort = mkOption {
      type = port;
      default = 8812;
      description = ''questdb server listen pg port'';
    };
    lineAddress = mkOption {
      type = str;
      default = "0.0.0.0";
      description = ''questdb server IP address to bind to for the line server. see https://questdb.io/docs/configuration/#influxdb-line-protocol-ilp'';
    };
    linePort = mkOption {
      type = port;
      default = 9009;
      description = ''questdb server listen line port'';
    };
    secretFile = mkOption {
      type = nullOr path;
      default = null;
      description = "example: /etc/default/questdb";
    };
    tag = mkOption {
      type = str;
      default = "questdb";
      description = "Expects a tag string value which will be as a tag for the service. This option allows users to run several QuestDB services and manage them separately.";
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

    systemd.services.questdb = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        HOME = cfg.dataDir;
        USER = cfg.user;
        QDB_TELEMETRY_ENABLED = "false";
        QDB_HTTP_BIND_TO = "${cfg.httpAddress}:${toString cfg.httpPort}";
        QDB_LINE_TCP_NET_BIND_TO = "${cfg.lineAddress}:${toString cfg.linePort}";
        QDB_LINE_UDP_BIND_TO = "${cfg.lineAddress}:${toString cfg.linePort}";
        QDB_PG_NET_BIND_TO = "${cfg.pgAddress}:${toString cfg.pgPort}";
      };

      serviceConfig = let qdb = "${cfg.package}/bin/questdb.sh"; in {
        Type = "forking";
        ${if cfg.secretFile != null then "EnvironmentFile" else null} = cfg.secretFile;
        ExecStart = ''${qdb} -f -d "${cfg.dataDir}" -n -t "${cfg.tag}"'';
        ExecStop = ''${qdb} -d "${cfg.dataDir}" -t "${cfg.tag}"'';
        StateDirectory = "questdb";
        User = cfg.user;
        WorkingDirectory = cfg.dataDir;
        PIDFile = "/run/.pid";
      };
    };
  };
}
