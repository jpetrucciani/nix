{ config, pkgs, lib, ... }:
let
  inherit (lib.types) mkOption mkIf path port str;
  cfg = config.services.valheim;
in
{
  imports = [ ];

  options.services.valheim = {
    enable = mkEnableOption "valheim";
    secretFile = mkOption {
      type = path;
      default = "/etc/default/valheim";
      description = "";
    };
    homeDir = mkOption {
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
  };

  config = mkIf cfg.enable {
    users.users.valheim = {
      # Valheim puts save data in the home directory.
      home = cfg.homeDir;
      group = "valheim";
      createHome = true;
      isSystemUser = true;
    };
    users.groups.valheim = { };

    systemd.services.valheim = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        EnvironmentFile = cfg.secretFile;
        ExecStartPre = ''
          ${pkgs.steamcmd}/bin/steamcmd \
            +force_install_dir ${cfg.homeDir} \
            +login anonymous \
            +app_update 896660 \
            +quit
        '';
        ExecStart = ''
          ${pkgs.steam-run}/bin/steam-run ./valheim_server.x86_64 \
            -name "${cfg.serverName}" \
            -port ${toString cfg.port} \
            -world "${cfg.world}" \
            -password "$VALHEIM_PASSWORD" \
            -public 1
        '';
        Nice = "-5";
        Restart = "always";
        StateDirectory = "valheim";
        User = "valheim";
        WorkingDirectory = cfg.homeDir;
      };
      environment = {
        # linux64 directory is required by Valheim.
        LD_LIBRARY_PATH = "linux64:${pkgs.glibc}/lib";
      };
    };
  };
}
