{ config, pkgs, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption literalExpression;
  inherit (lib.types) path str package port;
  cfg = config.services.obligator;
in
{
  imports = [ ];

  options.services.obligator = {
    enable = mkEnableOption "obligator";
    user = mkOption {
      type = str;
      default = "obligator";
      description = "User account under which obligator runs";
    };
    group = mkOption {
      type = str;
      default = "obligator";
      description = "Group under which obligator runs";
    };
    dataDir = mkOption {
      type = path;
      default = "/var/lib/obligator";
      description = ''the data directory for obligator'';
    };
    package = mkOption {
      default = pkgs.obligator;
      defaultText = literalExpression "pkgs.obligator";
      type = package;
      description = ''obligator package to use'';
    };
    port = mkOption {
      type = port;
      default = 1616;
      description = ''the port to run obligator on'';
    };
    displayName = mkOption {
      type = str;
      default = "obligator";
      description = "display name for the service";
    };
    geoDbPath = mkOption {
      type = str;
      default = "";
      description = "path to a geo ip db path";
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
    systemd.services.obligator =
      let
        extraArgs = if cfg.geoDbPath == "" then "" else "-geo-db-path ${cfg.geoDbPath}";
      in
      {
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          EnvironmentFile = cfg.secretFile;
          ExecStart = ''
            ${cfg.package}/bin/obligator ${extraArgs} \
              -behind-proxy true \
              -display-name "${cfg.displayName}" \
              -port "${toString cfg.port}"
          '';
          Restart = "on-failure";
          StateDirectory = "obligator";
          User = cfg.user;
          WorkingDirectory = cfg.dataDir;
        };
      };
  };
}
