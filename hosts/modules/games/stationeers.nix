{ config, pkgs, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption;
  inherit (lib.types) path port str number;
  cfg = config.services.stationeers;
in
{
  imports = [ ];

  options.services.stationeers = {
    enable = mkEnableOption "stationeers";
    user = mkOption {
      type = str;
      default = "stationeers";
      description = "User account under which stationeers runs";
    };
    group = mkOption {
      type = str;
      default = "stationeers";
      description = "Group under which stationeers runs";
    };
    dataDir = mkOption {
      type = path;
      default = "/var/lib/stationeers";
      description = "where on disk to store your stationeers directory";
    };
    port = mkOption {
      type = port;
      default = 27016;
      description = "the port to use";
    };
    maxPlayers = mkOption {
      type = number;
      default = 30;
      description = "the amount of players to support";
    };
    saveInterval = mkOption {
      type = number;
      default = 300;
      description = "time in between auto saves";
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
      type = path;
      default = "/etc/default/stationeers";
      description = "the secret file";
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

    systemd.services.stationeers = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        EnvironmentFile = "-${cfg.secretFile}";
        ExecStartPre = ''
          ${pkgs.steamcmd}/bin/steamcmd \
            +force_install_dir ${cfg.dataDir} \
            +login anonymous \
            +app_update 600760 \
            +quit
        '';
        ExecStart = ''
          ${pkgs.steam-run}/bin/steam-run ./rocketstation_DedicatedServer.x86_64 \
            -load "${cfg.worldName}" moon \
            -settings \
            ServerName "${cfg.serverName}" \
            StartLocalHost true \
            ServerVisible true \
            GamePort "${toString cfg.port}" \
            AutoSave true \
            SaveInterval "${toString cfg.saveInterval}" \
            ServerPassword "$STATIONEERS_PASSWORD" \
            ServerMaxPlayers ${toString cfg.maxPlayers} \
            UPNPEnabled false
        '';
        Nice = "-5";
        Restart = "always";
        StateDirectory = "stationeers";
        User = cfg.user;
        WorkingDirectory = cfg.dataDir;
      };
      environment = {
        # linux64 directory is required by stationeers.
        LD_LIBRARY_PATH = "linux64:${pkgs.glibc}/lib";
      };
    };
  };
}
