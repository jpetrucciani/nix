{ config, lib, pkgs, ... }:
let
  inherit (lib) literalExpression mkEnableOption mkIf mkOption optionalAttrs recursiveUpdate;
  inherit (lib.types) attrs attrsOf bool enum int listOf nullOr package path port str submodule;

  cfg = config.services.semaphore;
  settingsFormat = pkgs.formats.json { };

  databaseSettings =
    let
      commonSql = {
        host =
          if cfg.database.host != null then cfg.database.host
          else if cfg.database.dialect == "postgres" then "127.0.0.1:5432"
          else "127.0.0.1:3306";
        user = cfg.database.user;
        name = cfg.database.name;
      } // optionalAttrs (cfg.database.options != { }) {
        options = cfg.database.options;
      };

      fileDb = defaultName: {
        host =
          if cfg.database.host != null then cfg.database.host
          else "${toString cfg.dataDir}/${defaultName}";
      } // optionalAttrs (cfg.database.options != { }) {
        options = cfg.database.options;
      };
    in
    {
      dialect = cfg.database.dialect;
    } // (
      if cfg.database.dialect == "sqlite" then {
        sqlite = fileDb "database.sqlite";
      } else if cfg.database.dialect == "bolt" then {
        bolt = fileDb "database.boltdb";
      } else if cfg.database.dialect == "postgres" then {
        postgres = commonSql;
      } else {
        mysql = commonSql;
      }
    );

  generatedSettings = recursiveUpdate
    (
      recursiveUpdate databaseSettings (
        {
          port = toString cfg.port;
          interface = cfg.listenAddress;
          tmp_path = "${toString cfg.dataDir}/tmp";
          home_dir_mode = cfg.homeDirMode;
          git_client = cfg.gitClient;

          tls = {
            enabled = false;
            cert_file = "";
            key_file = "";
          };
          mfa = {
            totp = {
              enabled = cfg.totp.enable;
              allow_recovery = cfg.totp.allowRecovery;
              app_name = cfg.totp.issuer;
            };
            email = {
              enabled = false;
              allow_login_as_external_user = false;
              allow_create_external_user = false;
              allowed_domains = [ ];
              disable_for_oidc = false;
            };
          };
          log = {
            events = {
              enabled = false;
            };
            tasks = {
              enabled = false;
            };
          };
          process = {
            no_new_privs = false;
            app_namespaces = {
              user = false;
              mount = false;
              pid = false;
              ipc = false;
              uts = false;
            };
          };
          schedule = {
            timezone = cfg.scheduleTimezone;
          };
          debugging = {
            api_delay = "";
            pprof_dump_dir = "";
          };
          ha = {
            enabled = false;
          };
          subscription = {
            key_file = "";
          };
          dirs = {
            secrets = "${toString cfg.dataDir}/secrets";
            repos = "${toString cfg.dataDir}/repositories";
            ssh_agent_sockets = "${toString cfg.dataDir}/ssh-agent-sockets";
          };
          syslog = {
            enabled = false;
          };
        } // optionalAttrs (cfg.webHost != null) {
          web_host = cfg.webHost;
        } // optionalAttrs (cfg.maxParallelTasks != null) {
          max_parallel_tasks = cfg.maxParallelTasks;
        }
      )
    )
    cfg.settings;

  configFile =
    if cfg.configFile != null then
      cfg.configFile
    else
      settingsFormat.generate "semaphore.json" generatedSettings;

  execArgs = [
    "${cfg.package}/bin/semaphore"
    "server"
    "--config"
    (toString configFile)
  ] ++ cfg.extraArgs;
in
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "services" "semaphore" "environmentFile" ]
      [ "services" "semaphore" "envFile" ])
  ];

  options.services.semaphore = {
    enable = mkEnableOption "Semaphore UI";

    package = mkOption {
      type = package;
      default = pkgs.semaphore;
      defaultText = literalExpression "pkgs.semaphore";
      description = "Semaphore UI package to use.";
    };

    user = mkOption {
      type = str;
      default = "semaphore";
      description = "User account under which Semaphore runs.";
    };

    group = mkOption {
      type = str;
      default = "semaphore";
      description = "Group under which Semaphore runs.";
    };

    dataDir = mkOption {
      type = path;
      default = "/var/lib/semaphore";
      description = "Semaphore state directory.";
    };

    configFile = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        Path to an existing Semaphore JSON or YAML config. When this is set,
        generated settings and services.semaphore.settings are ignored.
      '';
      example = "/etc/semaphore/config.json";
    };

    envFile = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        Optional systemd EnvironmentFile for secrets and environment overrides.
        Generate key material with `openssl rand -base64 32`. Useful keys include
        SEMAPHORE_COOKIE_HASH, SEMAPHORE_COOKIE_ENCRYPTION,
        SEMAPHORE_ACCESS_KEY_ENCRYPTION, SEMAPHORE_DB_PASS, and alerting tokens.
      '';
      example = "/run/agenix/semaphore.env";
    };

    database = mkOption {
      type = submodule {
        options = {
          dialect = mkOption {
            type = enum [
              "sqlite"
              "postgres"
              "mysql"
              "bolt"
            ];
            default = "sqlite";
            description = "Semaphore database dialect.";
          };

          host = mkOption {
            type = nullOr str;
            default = null;
            description = ''
              Database host, or file path for sqlite/bolt. Defaults to
              dataDir/database.sqlite for sqlite, dataDir/database.boltdb for
              bolt, 127.0.0.1:5432 for postgres, and 127.0.0.1:3306 for mysql.
            '';
          };

          user = mkOption {
            type = str;
            default = "semaphore";
            description = "Database user for postgres/mysql.";
          };

          name = mkOption {
            type = str;
            default = "semaphore";
            description = "Database name for postgres/mysql.";
          };

          options = mkOption {
            type = attrsOf str;
            default = { };
            description = "Database driver options rendered under the selected database config.";
            example = literalExpression ''
              {
                sslmode = "disable";
              }
            '';
          };
        };
      };
      default = { };
      description = "Typed database configuration used to generate Semaphore config.";
    };

    listenAddress = mkOption {
      type = str;
      default = "127.0.0.1";
      description = "Address Semaphore listens on.";
    };

    port = mkOption {
      type = port;
      default = 3000;
      description = "Port Semaphore listens on.";
    };

    webHost = mkOption {
      type = nullOr str;
      default = null;
      description = "Public URL for Semaphore links and redirects.";
      example = "https://semaphore.example.com";
    };

    homeDirMode = mkOption {
      type = enum [
        "user_home"
        "project_home"
        "template_dir"
      ];
      default = "template_dir";
      description = "How Semaphore sets HOME for task runs.";
    };

    gitClient = mkOption {
      type = enum [
        "cmd_git"
        "go_git"
      ];
      default = "cmd_git";
      description = "Semaphore Git client implementation.";
    };

    scheduleTimezone = mkOption {
      type = str;
      default = "UTC";
      description = "Timezone used by Semaphore schedules.";
    };

    maxParallelTasks = mkOption {
      type = nullOr int;
      default = null;
      description = "Maximum number of parallel tasks. Null uses Semaphore's upstream default.";
    };

    totp = {
      enable = mkEnableOption "Semaphore TOTP MFA";

      allowRecovery = mkOption {
        type = bool;
        default = false;
        description = "Allow TOTP recovery codes.";
      };

      issuer = mkOption {
        type = str;
        default = "Semaphore";
        description = "TOTP issuer name.";
      };
    };

    settings = mkOption {
      inherit (settingsFormat) type;
      default = { };
      description = ''
        Raw Semaphore JSON settings merged over this module's generated config.
        Use this for upstream options that do not have first-class NixOS options.
        Sensitive values should usually go in envFile instead of the Nix store.
      '';
      example = literalExpression ''
        {
          oidc_providers = {
            authentik = {
              display_name = "Authentik";
              provider_url = "https://auth.example.com/application/o/semaphore/";
              client_id = "semaphore";
              client_secret_file = "/run/agenix/semaphore-oidc-client-secret";
            };
          };
        }
      '';
    };

    openFirewall = mkEnableOption "firewall rule for the Semaphore HTTP listener";

    extraPackages = mkOption {
      type = listOf package;
      default = with pkgs; [
        ansible
        git
        openssh
      ];
      defaultText = literalExpression "with pkgs; [ ansible git openssh ]";
      description = ''
        Packages added to the Semaphore service PATH for running task apps.
        Add terraform, opentofu, terragrunt, powershell, or other tools here.
      '';
    };

    extraArgs = mkOption {
      type = listOf str;
      default = [ ];
      description = "Additional arguments passed to `semaphore server`.";
    };

    extraReadWritePaths = mkOption {
      type = listOf path;
      default = [ ];
      description = "Additional paths Semaphore may write to under the systemd sandbox.";
    };

    serviceConfig = mkOption {
      type = attrs;
      default = { };
      description = "Extra systemd serviceConfig settings for semaphore.service.";
      example = literalExpression ''
        {
          RestartSec = 10;
        }
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

    systemd.tmpfiles.rules = [
      "d ${toString cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.dataDir}/repositories 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.dataDir}/secrets 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.dataDir}/ssh-agent-sockets 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.dataDir}/tmp 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.semaphore = {
      description = "Semaphore UI";
      documentation = [ "https://github.com/semaphoreui/semaphore" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = cfg.extraPackages;

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = lib.escapeShellArgs execArgs;
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "on-failure";
        RestartSec = 3;

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        ReadWritePaths = [
          cfg.dataDir
        ] ++ cfg.extraReadWritePaths;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";

        StandardOutput = "journal";
        StandardError = "journal";
      } // optionalAttrs (cfg.envFile != null) {
        EnvironmentFile = cfg.envFile;
      } // cfg.serviceConfig;
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };
}
