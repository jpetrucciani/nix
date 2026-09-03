{ config, lib, pkgs, ... }:
let
  inherit (lib) attrNames concatMap filterAttrs flatten literalExpression mapAttrs' mapAttrsToList mkEnableOption mkIf mkOption nameValuePair optionalAttrs unique;
  inherit (lib.types) attrs attrsOf bool float int listOf oneOf package path port str submodule;

  cfg = config.services.whisper-cpp;
  settingValueType = oneOf [
    bool
    int
    float
    str
    path
  ];
  reservedSettings = [
    "host"
    "model"
    "port"
    "tmp-dir"
  ];

  instanceType = submodule (
    _:
    {
      options = {
        enable = mkOption {
          type = bool;
          default = true;
          description = "Whether to run this whisper.cpp instance.";
        };

        package = mkOption {
          type = package;
          default = cfg.package;
          defaultText = literalExpression "config.services.whisper-cpp.package";
          description = "whisper.cpp package used by this instance.";
        };

        model = mkOption {
          type = path;
          description = "Absolute path to the GGML Whisper model loaded by this instance.";
          example = "/var/lib/whisper-cpp/models/ggml-large-v3-turbo.bin";
        };

        address = mkOption {
          type = str;
          default = "127.0.0.1";
          description = "Address on which this instance listens.";
        };

        port = mkOption {
          type = port;
          description = "TCP port on which this instance listens.";
          example = 8080;
        };

        settings = mkOption {
          type = attrsOf settingValueType;
          default = { };
          example = literalExpression ''
            {
              threads = 8;
              language = "auto";
              vad = true;
              "vad-model" = "/var/lib/whisper-cpp/models/ggml-silero-v6.2.0.bin";
            }
          '';
          description = ''
            whisper-server long options, keyed without the leading `--`.
            Boolean true emits a flag and false omits it. The module manages
            host, port, model, and tmp-dir separately.
          '';
        };

        extraArgs = mkOption {
          type = listOf str;
          default = [ ];
          description = "Additional arguments appended to the whisper-server command.";
        };

        extraEnvironment = mkOption {
          type = attrsOf str;
          default = { };
          description = "Non-secret environment variables for this instance.";
        };

        environmentFiles = mkOption {
          type = listOf path;
          default = [ ];
          description = "Runtime environment files for this instance.";
        };

        extraPackages = mkOption {
          type = listOf package;
          default = [ ];
          example = literalExpression "[ pkgs.ffmpeg-headless ]";
          description = "Additional packages placed on this instance's PATH.";
        };

        openFirewall = mkOption {
          type = bool;
          default = false;
          description = "Whether to open this instance's TCP port in the firewall.";
        };

        serviceConfig = mkOption {
          type = attrs;
          default = { };
          description = "Extra systemd serviceConfig settings for this instance.";
        };
      };
    }
  );

  enabledInstances = filterAttrs (_: instance: instance.enable) cfg.instances;
  instanceName = name: "whisper-cpp-${name}";
  instanceDir = name: "${toString cfg.stateDir}/${name}";

  settingArgs = settings:
    flatten (
      mapAttrsToList
        (
          name: value:
            if builtins.isBool value then
              if value then [ "--${name}" ] else [ ]
            else
              [
                "--${name}"
                (toString value)
              ]
        )
        settings
    );

  execStartFor = name: instance:
    lib.escapeShellArgs (
      [
        (lib.getExe' instance.package "whisper-server")
        "--host"
        instance.address
        "--port"
        (toString instance.port)
        "--model"
        (toString instance.model)
        "--tmp-dir"
        "${instanceDir name}/tmp"
      ]
      ++ settingArgs instance.settings
      ++ instance.extraArgs
    );

  instanceAssertions = name: instance:
    let
      settingNames = attrNames instance.settings;
      invalidSettingNames = builtins.filter
        (setting: builtins.match "^[a-z0-9][a-z0-9-]*$" setting == null)
        settingNames;
      managedSettingNames = builtins.filter (setting: builtins.elem setting reservedSettings) settingNames;
    in
    [
      {
        assertion = builtins.match "^[a-z0-9][a-z0-9_-]*$" name != null;
        message = "services.whisper-cpp.instances.${name}: instance names may contain lowercase letters, digits, underscores, and hyphens.";
      }
      {
        assertion = invalidSettingNames == [ ];
        message = "services.whisper-cpp.instances.${name}.settings contains an invalid long-option name.";
      }
      {
        assertion = managedSettingNames == [ ];
        message = "services.whisper-cpp.instances.${name}.settings may not override host, port, model, or tmp-dir.";
      }
    ];
in
{
  options.services.whisper-cpp = {
    enable = mkEnableOption "multi-instance whisper.cpp HTTP servers";

    package = mkOption {
      type = package;
      default = pkgs.whisper-cpp-latest;
      defaultText = literalExpression "pkgs.whisper-cpp-latest";
      description = "Default whisper.cpp package for all instances.";
    };

    user = mkOption {
      type = str;
      default = "whisper-cpp";
      description = "User account under which all whisper.cpp instances run.";
    };

    group = mkOption {
      type = str;
      default = "whisper-cpp";
      description = "Group under which all whisper.cpp instances run.";
    };

    createUser = mkOption {
      type = bool;
      default = true;
      description = "Whether to create the configured service user and group.";
    };

    supplementaryGroups = mkOption {
      type = listOf str;
      default = [ ];
      example = [
        "video"
        "render"
      ];
      description = "Supplementary groups used when creating the service user, for example GPU device-access groups.";
    };

    stateDir = mkOption {
      type = path;
      default = "/var/lib/whisper-cpp";
      description = "Writable state directory containing per-instance cache and temporary files.";
    };

    extraEnvironment = mkOption {
      type = attrsOf str;
      default = { };
      description = "Non-secret environment variables shared by all instances.";
    };

    environmentFiles = mkOption {
      type = listOf path;
      default = [ ];
      description = "Runtime environment files shared by all instances.";
    };

    extraPackages = mkOption {
      type = listOf package;
      default = [ ];
      description = "Additional packages placed on every instance's PATH.";
    };

    instances = mkOption {
      type = attrsOf instanceType;
      default = { };
      description = "Named whisper.cpp server instances.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          let
            ports = mapAttrsToList (_: instance: instance.port) enabledInstances;
          in
          builtins.length ports == builtins.length (unique ports);
        message = "Enabled services.whisper-cpp instances must use distinct ports.";
      }
    ] ++ concatMap (name: instanceAssertions name enabledInstances.${name}) (attrNames enabledInstances);

    users.users.${cfg.user} = mkIf cfg.createUser {
      inherit (cfg) group;
      extraGroups = cfg.supplementaryGroups;
      home = cfg.stateDir;
      isSystemUser = true;
    };
    users.groups.${cfg.group} = mkIf cfg.createUser { };

    systemd.tmpfiles.rules = [
      "d ${toString cfg.stateDir} 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.stateDir}/models 0750 ${cfg.user} ${cfg.group} -"
    ] ++ flatten (
      mapAttrsToList
        (
          name: _:
            [
              "d ${instanceDir name} 0750 ${cfg.user} ${cfg.group} -"
              "d ${instanceDir name}/cache 0750 ${cfg.user} ${cfg.group} -"
              "d ${instanceDir name}/tmp 0750 ${cfg.user} ${cfg.group} -"
            ]
        )
        enabledInstances
    );

    systemd.services = mapAttrs'
      (
        name: instance:
          let
            runtimeDir = instanceDir name;
            environmentFiles = cfg.environmentFiles ++ instance.environmentFiles;
          in
          nameValuePair (instanceName name) {
            description = "whisper.cpp server instance ${name}";
            documentation = [ "https://github.com/ggml-org/whisper.cpp/tree/master/examples/server" ];
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            environment = {
              HOME = runtimeDir;
              XDG_CACHE_HOME = "${runtimeDir}/cache";
              TMPDIR = "${runtimeDir}/tmp";
            } // cfg.extraEnvironment // instance.extraEnvironment;
            path = cfg.extraPackages ++ instance.extraPackages;

            serviceConfig = {
              ExecStart = execStartFor name instance;
              User = cfg.user;
              Group = cfg.group;
              WorkingDirectory = runtimeDir;
              Restart = "on-failure";
              RestartSec = 10;
              ReadWritePaths = [ runtimeDir ];
              NoNewPrivileges = true;
              PrivateTmp = true;
              ProtectHome = "read-only";
              ProtectSystem = "strict";
              RestrictSUIDSGID = true;
              UMask = "0027";
            }
            // optionalAttrs (environmentFiles != [ ]) {
              EnvironmentFile = map toString environmentFiles;
            }
            // instance.serviceConfig;
          }
      )
      enabledInstances;

    networking.firewall.allowedTCPPorts = mapAttrsToList
      (_: instance: instance.port)
      (filterAttrs (_: instance: instance.openFirewall) enabledInstances);
  };
}
