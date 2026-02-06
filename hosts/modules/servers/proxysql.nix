{ config, lib, pkgs, ... }:
let
  inherit (lib) filterAttrs literalExpression mapAttrs' mapAttrsToList mkEnableOption mkIf mkOption nameValuePair optionalString;
  inherit (lib.types) attrsOf lines listOf nullOr package path str submodule;
  cfg = config.services.proxysql;

  proxysqlName = name: "proxysql" + optionalString (name != "default") "-${name}";
  enabledInstances = filterAttrs (_: instance: instance.enable) cfg.instances;

  configPathFor = name: instance:
    if instance.configText != null then
      pkgs.writeText "proxysql-${name}.cnf" instance.configText
    else
      instance.configFile;

  execStartFor = name: instance:
    lib.escapeShellArgs (
      [
        "${instance.package}/bin/proxysql"
        "--config"
        (toString (configPathFor name instance))
        "--datadir"
        instance.dataDir
      ]
      ++ instance.extraArgs
    );
in
{
  imports = [ ];

  options.services.proxysql = {
    instances = mkOption {
      type = attrsOf (submodule ({ name, ... }: {
        options = {
          enable = mkEnableOption "proxysql instance ${name}";
          dataDir = mkOption {
            type = path;
            default = "/var/lib/proxysql" + optionalString (name != "default") "/${name}";
            description = "data directory for proxysql instance";
          };
          package = mkOption {
            default = pkgs.proxysql;
            defaultText = literalExpression "pkgs.proxysql";
            type = package;
            description = "proxysql package to use";
          };
          configFile = mkOption {
            type = path;
            default = "/etc/proxysql" + optionalString (name != "default") "-${name}" + ".cnf";
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
      }));
      default = { };
      description = "named proxysql instances";
      example = literalExpression ''
        {
          default = {
            enable = true;
            configFile = "/etc/proxysql.cnf";
          };
          analytics = {
            enable = true;
            configFile = "/etc/proxysql-analytics.cnf";
          };
        }
      '';
    };
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
  };

  config = mkIf (enabledInstances != { }) {
    users.users.${cfg.user} = {
      inherit (cfg) group;
      home = "/var/lib/proxysql";
      createHome = true;
      isSystemUser = true;
    };
    users.groups.${cfg.group} = { };

    systemd.tmpfiles.rules = mapAttrsToList
      (_: instance: "d ${toString instance.dataDir} 0750 ${cfg.user} ${cfg.group} -")
      enabledInstances;

    systemd.services = mapAttrs'
      (name: instance:
        nameValuePair (proxysqlName name) {
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = execStartFor name instance;
            Restart = "on-failure";
            User = cfg.user;
            Group = cfg.group;
            WorkingDirectory = instance.dataDir;
          };
        })
      enabledInstances;
  };
}
