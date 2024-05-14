{ config, pkgs, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption mdDoc;
  inherit (lib.types) path str;
  cfg = config.services.goto;
in
{
  imports = [ ];

  options.services.goto = {
    enable = mkEnableOption "goto";
    user = mkOption {
      type = str;
      default = "goto";
      description = mdDoc "User account under which goto runs";
    };
    group = mkOption {
      type = str;
      default = "goto";
      description = mdDoc "Group under which goto runs";
    };
    dataDir = mkOption {
      type = path;
      default = "/var/lib/goto";
      description = mdDoc ''the data directory for goto'';
    };
    secretFile = mkOption {
      type = path;
      default = "/etc/default/goto";
      description = mdDoc ''secret env variables for goto'';
    };

    execFile = mkOption {
      type = path;
      default = "/var/lib/goto/goto";
      description = mdDoc ''the executable file for goto'';
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

    systemd.services.goto = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        EnvironmentFile = cfg.secretFile;
        ExecStart = cfg.execFile;
        Restart = "on-failure";
        StateDirectory = "goto";
        User = cfg.user;
        WorkingDirectory = cfg.dataDir;
      };
    };
  };
}
