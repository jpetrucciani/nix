{ config, lib, pkgs, ... }:
let
  inherit (lib)
    getExe
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    optionalAttrs
    recursiveUpdate
    ;
  inherit (lib.types) attrs listOf nullOr package path str;

  cfg = config.services.viz;
  settingsFormat = pkgs.formats.toml { };

  generatedSettings = recursiveUpdate cfg.settings {
    server = {
      state_dir = toString cfg.dataDir;
      backup_dir = toString cfg.backupDir;
    };
  };
  configFile =
    if cfg.configFile != null then
      cfg.configFile
    else
      settingsFormat.generate "viz.toml" generatedSettings;
  execArgs = [
    (getExe cfg.package)
    "serve"
    "--config"
    (toString configFile)
  ] ++ cfg.extraArgs;
in
{
  imports = [ ];

  options.services.viz = {
    enable = mkEnableOption "Viz live-rendered Markdown notebook server";

    package = mkOption {
      type = package;
      default = pkgs.viz;
      defaultText = literalExpression "pkgs.viz";
      description = "Viz package to use.";
    };

    user = mkOption {
      type = str;
      default = "viz";
      description = "User account under which Viz runs.";
    };

    group = mkOption {
      type = str;
      default = "viz";
      description = "Group under which Viz runs.";
    };

    dataDir = mkOption {
      type = path;
      default = "/var/lib/viz";
      description = "Viz state directory.";
    };

    backupDir = mkOption {
      type = path;
      default = "/var/backups/viz";
      description = "Directory where Viz writes verified SQLite backups.";
    };

    configFile = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        Path to an existing Viz TOML config. When this is set, settings,
        dataDir, and backupDir are not rendered into the config file.
      '';
      example = "/etc/viz/viz.toml";
    };

    environmentFile = mkOption {
      type = nullOr str;
      default = "-/etc/default/viz";
      description = ''
        systemd EnvironmentFile containing runtime environment variables and
        secrets. The default leading dash makes a missing file non-fatal. Set
        this to null to disable it, or omit the dash from a custom path to make
        that file required. Restart viz.service after changing environment-
        backed secrets; SIGHUP only reloads file-backed Viz secrets.
      '';
    };

    settings = mkOption {
      inherit (settingsFormat) type;
      default = {
        server = {
          bind = "127.0.0.1:3000";
          local = false;
          allow_multi_instance = false;
          insecure_no_auth = false;
          allow_public_shares = false;
          trusted_proxies = [ "127.0.0.1" ];
        };
      };
      description = ''
        Non-secret Viz TOML settings rendered to the config file passed to viz
        serve. The server state_dir and backup_dir are set from dataDir and
        backupDir. Reference environment-backed secrets here and put their
        values in environmentFile so secret material does not enter the Nix
        store.
      '';
      example = literalExpression ''
        {
          server = {
            bind = "127.0.0.1:3000";
            metrics_token_secret = "prometheus_token";
            trusted_proxies = [ "127.0.0.1" ];
          };
          client.server = "https://viz.example.com";
          oidc.providers.google = {
            issuer = "https://accounts.google.com";
            client_id = "REPLACE_WITH_GOOGLE_CLIENT_ID";
            client_secret = "google_oidc";
            redirect_uri = "https://viz.example.com/api/auth/oidc/google/callback";
            trusted_email_linking = true;
            allowed_emails = [ "friend@example.net" ];
            allowed_domains = [ "example.com" ];
            admin_emails = [ "you@example.com" ];
          };
          secrets = {
            google_oidc.env = "VIZ_GOOGLE_CLIENT_SECRET";
            prometheus_token.env = "VIZ_PROMETHEUS_TOKEN";
          };
        }
      '';
    };

    extraArgs = mkOption {
      type = listOf str;
      default = [ ];
      description = "Additional arguments passed to viz serve.";
    };

    extraReadWritePaths = mkOption {
      type = listOf path;
      default = [ ];
      description = "Additional paths Viz may write to under the systemd sandbox.";
    };

    serviceConfig = mkOption {
      type = attrs;
      default = { };
      description = "Extra systemd serviceConfig settings for viz.service.";
      example = literalExpression ''
        {
          RestartSec = 5;
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
      "d ${toString cfg.backupDir} 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.viz = {
      description = "Viz live-rendered Markdown notebook server";
      documentation = [ "https://github.com/jpetrucciani/viz" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        HOME = toString cfg.dataDir;
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = lib.escapeShellArgs execArgs;
        ExecReload = "${lib.getExe' pkgs.coreutils "kill"} -HUP $MAINPID";
        Restart = "on-failure";
        RestartSec = 2;
        UMask = "0077";

        NoNewPrivileges = true;

        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        PrivateDevices = true;
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
          cfg.backupDir
        ] ++ cfg.extraReadWritePaths;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";

        StandardOutput = "journal";
        StandardError = "journal";
      } // optionalAttrs (cfg.environmentFile != null) {
        EnvironmentFile = cfg.environmentFile;
      } // cfg.serviceConfig;
    };
  };
}
