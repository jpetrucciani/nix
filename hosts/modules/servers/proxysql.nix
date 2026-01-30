{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption literalExpression;
  inherit (lib.types) listOf nullOr lines package path str;
  cfg = config.services.proxysql;

  configPath =
    if cfg.configText != null then
      pkgs.writeText "proxysql.cnf" cfg.configText
    else
      cfg.configFile;

  extraArgs = lib.concatStringsSep " " cfg.extraArgs;
  execStart = "${cfg.package}/bin/proxysql --config ${configPath} --datadir ${cfg.dataDir}"
    + lib.optionalString (extraArgs != "") " ${extraArgs}";
in
{
  imports = [ ];

  options.services.proxysql = {
    enable = mkEnableOption "proxysql";
    user = mkOption {
      type = str;
      default = "proxysql";
      description = "user account under which proxysql runs";
    };
    group = mkOption {
      type = str;
      default = "proxysql";
      description = "group under which proxysql runs";
    };
    dataDir = mkOption {
      type = path;
      default = "/var/lib/proxysql";
      description = "data directory for proxysql";
    };
    package = mkOption {
      default = pkgs.proxysql;
      defaultText = literalExpression "pkgs.proxysql";
      type = package;
      description = "proxysql package to use";
    };
    configFile = mkOption {
      type = path;
      default = "/etc/proxysql.cnf";
      description = "path to proxysql config file";
    };
    configText = mkOption {
      type = nullOr lines;
      default = null;
      description = ''
        proxysql config content. When set, a config file will be generated
        and used instead of configFile.
      '';
    };
    extraArgs = mkOption {
      type = listOf str;
      default = [ ];
      description = "extra CLI args passed to proxysql";
      example = [ "--initial" ];
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

    systemd.services.proxysql = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = execStart;
        Restart = "on-failure";
        StateDirectory = "proxysql";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
      };
    };
  };
}
