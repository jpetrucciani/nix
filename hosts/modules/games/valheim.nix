{ config, pkgs, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption;
  inherit (lib.types) nullOr path port str;
  cfg = config.services.valheim;
in
{
  imports = [ ];

  options.services.valheim = {
    enable = mkEnableOption "valheim";
    user = mkOption {
      type = str;
      default = "valheim";
      description = "User account under which valheim runs";
    };
    group = mkOption {
      type = str;
      default = "valheim";
      description = "Group under which valheim runs";
    };
    dataDir = mkOption {
      type = path;
      default = "/var/lib/valheim";
      description = "where on disk to store your valheim directory";
    };
    port = mkOption {
      type = port;
      default = 2456;
      description = "the port to use";
    };
    serverName = mkOption {
      type = str;
      default = "memeworld";
      description = "the broadcasted name of the server";
    };
    worldName = mkOption {
      type = str;
      default = "Dedicated";
      description = "the name of the world to use";
    };
    secretFile = mkOption {
      type = nullOr path;
      default = "/etc/default/valheim";
      description = ''
        this file contains any additional secrets you might want to pass in.

        You must have a "VALHEIM_PASSWORD" variable in this file.

        Note: VALHEIM_PASSWORD must be at least 8 characters!
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

    systemd.services.valheim = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ${if cfg.secretFile != null then "EnvironmentFile" else null} = "-${cfg.secretFile}";
        ExecStartPre = ''
          ${pkgs.steamcmd}/bin/steamcmd \
            +force_install_dir ${cfg.dataDir} \
            +login anonymous \
            +app_update 896660 \
            +quit
        '';
        ExecStart = ''
          ${pkgs.steam-run}/bin/steam-run ./valheim_server.x86_64 \
            -name "${cfg.serverName}" \
            -port ${toString cfg.port} \
            -world "${cfg.worldName}" \
            -password "$VALHEIM_PASSWORD" \
            -public 1
        '';
        Nice = "-5";
        Restart = "always";
        StateDirectory = "valheim";
        User = cfg.user;
        WorkingDirectory = cfg.dataDir;
      };
      environment = {
        # linux64 directory is required by Valheim.
        LD_LIBRARY_PATH = "linux64:${pkgs.glibc}/lib";
      };
    };
  };
}
