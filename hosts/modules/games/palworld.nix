{ config, pkgs, lib, ... }:
let
  inherit (lib) mdDoc mkIf mkEnableOption mkOption;
  inherit (lib.types) path port str number;
  cfg = config.services.palworld;
  join = builtins.concatStringsSep " ";
in
{
  imports = [ ];

  options.services.palworld = {
    enable = mkEnableOption "palworld";
    user = mkOption {
      type = str;
      default = "palworld";
      description = mdDoc "User account under which palworld runs";
    };
    group = mkOption {
      type = str;
      default = "palworld";
      description = mdDoc "Group under which palworld runs";
    };
    dataDir = mkOption {
      type = path;
      default = "/var/lib/palworld";
      description = "where on disk to store your palworld directory";
    };
    port = mkOption {
      type = port;
      default = 8211;
      description = "the port to use";
    };
    maxPlayers = mkOption {
      type = number;
      default = 32;
      description = "the amount of players to support";
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

    systemd.services.palworld = let dir = cfg.dataDir; in {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStartPre = join [
          "${pkgs.steamcmd}/bin/steamcmd"
          "+force_install_dir ${dir}"
          "+login anonymous"
          "+app_update 2394010"
          "+quit"
          "&& mkdir -p ${dir}/.steam/sdk64"
          "&& cp ${dir}/linux64/steamclient.so ${dir}/.steam/sdk64/."
        ];
        ExecStart = join [
          "${pkgs.steam-run}/bin/steam-run ${dir}/Pal/Binaries/Linux/PalServer-Linux-Test Pal"
          "--port ${toString cfg.port}"
          "--players ${toString cfg.maxPlayers}"
          "--useperfthreads"
          "-NoAsyncLoadingThread"
          "-UseMultithreadForDS"
        ];
        Nice = "-5";
        Restart = "always";
        StateDirectory = "palworld";
        User = cfg.user;
        WorkingDirectory = cfg.dataDir;
      };
      environment = {
        # linux64 directory is required by palworld.
        LD_LIBRARY_PATH = "linux64:${pkgs.glibc}/lib";
      };
    };
  };
}
