{ config, pkgs, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption literalExpression;
  inherit (lib.types) lines package path port str;
  cfg = config.services.poglets;
in
{
  imports = [ ];

  options.services.poglets = {
    enable = mkEnableOption "poglets";
    user = mkOption {
      type = str;
      default = "poglets";
      description = "User account under which poglets runs";
    };
    group = mkOption {
      type = str;
      default = "poglets";
      description = "Group under which poglets runs";
    };
    dataDir = mkOption {
      type = path;
      default = "/var/lib/poglets";
      description = ''the data directory for poglets'';
    };
    secretFile = mkOption {
      type = path;
      default = "/etc/default/poglets";
      description = ''secret env variables for poglets'';
    };
    package = mkOption {
      default = pkgs.poglets;
      defaultText = literalExpression "pkgs.poglets";
      type = package;
      description = ''poglets package to use'';
    };

    bindAddress = mkOption {
      type = str;
      default = "0.0.0.0";
      description = '''';
    };
    bindPort = mkOption {
      type = port;
      default = 8000;
      description = '''';
    };
    controlAddress = mkOption {
      type = str;
      default = "0.0.0.0";
      description = '''';
    };
    controlPort = mkOption {
      type = port;
      default = 8001;
      description = '''';
    };

    # extra
    extraConfig = mkOption {
      type = lines;
      default = "";
      example = '' '';
      description = lib ''
        Additional lines of configuration appended to the automatically generated poglets config.
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

    systemd.services.poglets = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        EnvironmentFile = cfg.secretFile;
        ExecStart = ''
          ${cfg.package}/bin/poglets server \
            --port ${toString cfg.bindPort} \
            --data-addr ${cfg.bindAddress} \
            --control-addr ${cfg.controlAddress} \
            --control-port ${toString cfg.controlPort} \
            --token "$POGLETS_TOKEN" 
        '';
        Restart = "on-failure";
        StateDirectory = "poglets";
        User = cfg.user;
        WorkingDirectory = cfg.dataDir;
      };
    };
  };
}
