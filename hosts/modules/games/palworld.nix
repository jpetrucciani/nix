{ config, pkgs, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption;
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
      description = "User account under which palworld runs";
    };
    group = mkOption {
      type = str;
      default = "palworld";
      description = "Group under which palworld runs";
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
    secretFile = mkOption {
      type = path;
      default = "/etc/default/palworld";
      description = "";
    };
    serverBinary = mkOption {
      type = str;
      default = "PalServer-Linux-Shipping"; # used to be PalServer-Linux-Test
      description = "the name of the binary to use";
    };
    # world settings
    worldSettings = {
      Difficulty = mkOption {
        type = str;
        default = "None";
      };
      DayTimeSpeedRate = mkOption {
        type = str;
        default = "1.000000";
      };
      NightTimeSpeedRate = mkOption {
        type = str;
        default = "1.000000";
      };
      ExpRate = mkOption {
        type = str;
        default = "1.000000";
      };
      PalCaptureRate = mkOption {
        type = str;
        default = "1.000000";
      };
      PalSpawnNumRate = mkOption {
        type = str;
        default = "1.000000";
      };
      PalDamageRateAttack = mkOption {
        type = str;
        default = "1.000000";
      };
      PalDamageRateDefense = mkOption {
        type = str;
        default = "1.000000";
      };
      PlayerDamageRateAttack = mkOption {
        type = str;
        default = "1.000000";
      };
      PlayerDamageRateDefense = mkOption {
        type = str;
        default = "1.000000";
      };
      PlayerStomachDecreaceRate = mkOption {
        type = str;
        default = "1.000000";
      };
      PlayerStaminaDecreaceRate = mkOption {
        type = str;
        default = "1.000000";
      };
      PlayerAutoHPRegeneRate = mkOption {
        type = str;
        default = "1.000000";
      };
      PlayerAutoHpRegeneRateInSleep = mkOption {
        type = str;
        default = "1.000000";
      };
      PalStomachDecreaceRate = mkOption {
        type = str;
        default = "1.000000";
      };
      PalStaminaDecreaceRate = mkOption {
        type = str;
        default = "1.000000";
      };
      PalAutoHPRegeneRate = mkOption {
        type = str;
        default = "1.000000";
      };
      PalAutoHpRegeneRateInSleep = mkOption {
        type = str;
        default = "1.000000";
      };
      BuildObjectDamageRate = mkOption {
        type = str;
        default = "1.000000";
      };
      BuildObjectDeteriorationDamageRate = mkOption {
        type = str;
        default = "1.000000";
      };
      CollectionDropRate = mkOption {
        type = str;
        default = "1.000000";
      };
      CollectionObjectHpRate = mkOption {
        type = str;
        default = "1.000000";
      };
      CollectionObjectRespawnSpeedRate = mkOption {
        type = str;
        default = "1.000000";
      };
      EnemyDropItemRate = mkOption {
        type = str;
        default = "1.000000";
      };
      DeathPenalty = mkOption {
        type = str;
        default = "1";
      };
      bEnablePlayerToPlayerDamage = mkOption {
        type = str;
        default = "False";
      };
      bEnableFriendlyFire = mkOption {
        type = str;
        default = "False";
      };
      bEnableInvaderEnemy = mkOption {
        type = str;
        default = "True";
      };
      bActiveUNKO = mkOption {
        type = str;
        default = "False";
      };
      bEnableAimAssistPad = mkOption {
        type = str;
        default = "True";
      };
      bEnableAimAssistKeyboard = mkOption {
        type = str;
        default = "False";
      };
      DropItemMaxNum = mkOption {
        type = str;
        default = "3000";
      };
      DropItemMaxNum_UNKO = mkOption {
        type = str;
        default = "100";
      };
      BaseCampMaxNum = mkOption {
        type = str;
        default = "128";
      };
      BaseCampWorkerMaxNum = mkOption {
        type = str;
        default = "15";
      };
      DropItemAliveMaxHours = mkOption {
        type = str;
        default = "1.000000";
      };
      bAutoResetGuildNoOnlinePlayers = mkOption {
        type = str;
        default = "False";
      };
      AutoResetGuildTimeNoOnlinePlayers = mkOption {
        type = str;
        default = "72.000000";
      };
      GuildPlayerMaxNum = mkOption {
        type = str;
        default = "20";
      };
      PalEggDefaultHatchingTime = mkOption {
        type = str;
        default = "10.000000";
      };
      WorkSpeedRate = mkOption {
        type = str;
        default = "1.000000";
      };
      bIsMultiplay = mkOption {
        type = str;
        default = "False";
      };
      bIsPvP = mkOption {
        type = str;
        default = "False";
      };
      bCanPickupOtherGuildDeathPenaltyDrop = mkOption {
        type = str;
        default = "False";
      };
      bEnableNonLoginPenalty = mkOption {
        type = str;
        default = "True";
      };
      bEnableFastTravel = mkOption {
        type = str;
        default = "True";
      };
      bIsStartLocationSelectByMap = mkOption {
        type = str;
        default = "True";
      };
      bExistPlayerAfterLogout = mkOption {
        type = str;
        default = "False";
      };
      bEnableDefenseOtherGuildPlayer = mkOption {
        type = str;
        default = "False";
      };
      CoopPlayerMaxNum = mkOption {
        type = str;
        default = toString cfg.maxPlayers;
      };
      ServerPlayerMaxNum = mkOption {
        type = str;
        default = toString cfg.maxPlayers;
      };
      PublicPort = mkOption {
        type = str;
        default = toString cfg.port;
      };
      RCONEnabled = mkOption {
        type = str;
        default = "False";
      };
      RCONPort = mkOption {
        type = str;
        default = "25575";
      };
      bUseAuth = mkOption {
        type = str;
        default = "True";
      };
      AdminPassword = mkOption {
        type = str;
        default = "";
        description = "the admin password for the server. leave unset for no admin functionality";
      };
      ServerPassword = mkOption {
        type = str;
        default = "";
        description = "the password to use on the server. leave empty for no password. you can use env vars like so: '$PALWORLD_SERVER_PASSWORD'";
      };
      ServerDescription = mkOption {
        type = str;
        default = "";
      };
      ServerName = mkOption {
        type = str;
        default = "nix-palworld";
      };
    };
  };

  config =
    let
      # server settings
      ws = cfg.worldSettings;
      world_settings = lib.concatStringsSep "," [
        "Difficulty=${ws.Difficulty}"
        "DayTimeSpeedRate=${ws.DayTimeSpeedRate}"
        "NightTimeSpeedRate=${ws.NightTimeSpeedRate}"
        "ExpRate=${ws.ExpRate}"
        "PalCaptureRate=${ws.PalCaptureRate}"
        "PalSpawnNumRate=${ws.PalSpawnNumRate}"
        "PalDamageRateAttack=${ws.PalDamageRateAttack}"
        "PalDamageRateDefense=${ws.PalDamageRateDefense}"
        "PlayerDamageRateAttack=${ws.PlayerDamageRateAttack}"
        "PlayerDamageRateDefense=${ws.PlayerDamageRateDefense}"
        "PlayerStomachDecreaceRate=${ws.PlayerStomachDecreaceRate}"
        "PlayerStaminaDecreaceRate=${ws.PlayerStaminaDecreaceRate}"
        "PlayerAutoHPRegeneRate=${ws.PlayerAutoHPRegeneRate}"
        "PlayerAutoHpRegeneRateInSleep=${ws.PlayerAutoHpRegeneRateInSleep}"
        "PalStomachDecreaceRate=${ws.PalStomachDecreaceRate}"
        "PalStaminaDecreaceRate=${ws.PalStaminaDecreaceRate}"
        "PalAutoHPRegeneRate=${ws.PalAutoHPRegeneRate}"
        "PalAutoHpRegeneRateInSleep=${ws.PalAutoHpRegeneRateInSleep}"
        "BuildObjectDamageRate=${ws.BuildObjectDamageRate}"
        "BuildObjectDeteriorationDamageRate=${ws.BuildObjectDeteriorationDamageRate}"
        "CollectionDropRate=${ws.CollectionDropRate}"
        "CollectionObjectHpRate=${ws.CollectionObjectHpRate}"
        "CollectionObjectRespawnSpeedRate=${ws.CollectionObjectRespawnSpeedRate}"
        "EnemyDropItemRate=${ws.EnemyDropItemRate}"
        "DeathPenalty=${ws.DeathPenalty}"
        "bEnablePlayerToPlayerDamage=${ws.bEnablePlayerToPlayerDamage}"
        "bEnableFriendlyFire=${ws.bEnableFriendlyFire}"
        "bEnableInvaderEnemy=${ws.bEnableInvaderEnemy}"
        "bActiveUNKO=${ws.bActiveUNKO}"
        "bEnableAimAssistPad=${ws.bEnableAimAssistPad}"
        "bEnableAimAssistKeyboard=${ws.bEnableAimAssistKeyboard}"
        "DropItemMaxNum=${ws.DropItemMaxNum}"
        "DropItemMaxNum_UNKO=${ws.DropItemMaxNum_UNKO}"
        "BaseCampMaxNum=${ws.BaseCampMaxNum}"
        "BaseCampWorkerMaxNum=${ws.BaseCampWorkerMaxNum}"
        "DropItemAliveMaxHours=${ws.DropItemAliveMaxHours}"
        "bAutoResetGuildNoOnlinePlayers=${ws.bAutoResetGuildNoOnlinePlayers}"
        "AutoResetGuildTimeNoOnlinePlayers=${ws.AutoResetGuildTimeNoOnlinePlayers}"
        "GuildPlayerMaxNum=${ws.GuildPlayerMaxNum}"
        "PalEggDefaultHatchingTime=${ws.PalEggDefaultHatchingTime}"
        "WorkSpeedRate=${ws.WorkSpeedRate}"
        "bIsMultiplay=${ws.bIsMultiplay}"
        "bIsPvP=${ws.bIsPvP}"
        "bCanPickupOtherGuildDeathPenaltyDrop=${ws.bCanPickupOtherGuildDeathPenaltyDrop}"
        "bEnableNonLoginPenalty=${ws.bEnableNonLoginPenalty}"
        "bEnableFastTravel=${ws.bEnableFastTravel}"
        "bIsStartLocationSelectByMap=${ws.bIsStartLocationSelectByMap}"
        "bExistPlayerAfterLogout=${ws.bExistPlayerAfterLogout}"
        "bEnableDefenseOtherGuildPlayer=${ws.bEnableDefenseOtherGuildPlayer}"
        "CoopPlayerMaxNum=${ws.CoopPlayerMaxNum}"
        "ServerPlayerMaxNum=${ws.ServerPlayerMaxNum}"
        "PublicPort=${ws.PublicPort}"
        "RCONEnabled=${ws.RCONEnabled}"
        "RCONPort=${ws.RCONPort}"
        "bUseAuth=${ws.bUseAuth}"
        ''ServerDescription="${ws.ServerDescription}"''
        ''AdminPassword="${ws.AdminPassword}"''
        ''ServerPassword="${ws.ServerPassword}"''
        ''Region=""''
        ''ServerName="${ws.ServerName}"''
        ''BanListURL="https://api.palworldgame.com/api/banlist.txt"''
      ];
      world_settings_text = ''
        [/Script/Pal.PalGameWorldSettings]
        OptionSettings=(${world_settings})
      '';
      world_settings_file = pkgs.writeTextFile {
        name = "PalWorldSettings.ini";
        text = world_settings_text;
      };
    in
    mkIf cfg.enable {
      users.users.${cfg.user} = {
        inherit (cfg) group;
        home = cfg.dataDir;
        createHome = true;
        isSystemUser = true;
      };
      users.groups.${cfg.group} = { };

      systemd.services.palworld =
        let
          dir = cfg.dataDir;
          pre_command = join [
            "${pkgs.steamcmd}/bin/steamcmd"
            "+force_install_dir ${dir}"
            "+login anonymous"
            "+app_update 2394010"
            "+quit"
            "&& mkdir -p ${dir}/.steam/sdk64"
            "&& cp ${dir}/linux64/steamclient.so ${dir}/.steam/sdk64/."
            "&& ls -alF ${world_settings_file}"
            "&& ${pkgs.envsubst}/bin/envsubst <${world_settings_file} >${dir}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini"
          ];
        in
        {
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            EnvironmentFile = cfg.secretFile;
            ExecStartPre = "${pkgs.bash}/bin/bash -c '${pre_command}'";
            ExecStart = join [
              "${pkgs.steam-run}/bin/steam-run ${dir}/Pal/Binaries/Linux/${cfg.serverBinary} Pal"
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
            LD_LIBRARY_PATH = "linux64:${pkgs.glibc}/lib";
          };
        };
    };
}
