{ config, lib, pkgs, ... }:
let
  inherit (lib) attrNames concatMap filterAttrs hasPrefix literalExpression mapAttrs' mapAttrsToList mkEnableOption mkIf mkOption nameValuePair optionalAttrs optionals unique;
  inherit (lib.types) attrs attrsOf bool float listOf nullOr package path port str submodule;

  cfg = config.services.sglang-omni;
  yamlFormat = pkgs.formats.yaml { };

  instanceType = submodule (
    _:
    {
      options = {
        enable = mkOption {
          type = bool;
          default = true;
          description = "Whether to run this SGLang-Omni instance.";
        };

        package = mkOption {
          type = package;
          default = cfg.package;
          defaultText = literalExpression "config.services.sglang-omni.package";
          description = "SGLang-Omni package used by this instance.";
        };

        modelPath = mkOption {
          type = str;
          description = "Hugging Face model ID or local model directory for this instance.";
        };

        address = mkOption {
          type = str;
          default = "127.0.0.1";
          description = "Address on which this instance listens.";
        };

        port = mkOption {
          type = port;
          description = "TCP port on which this instance listens.";
        };

        pipelineConfigClass = mkOption {
          type = nullOr str;
          default = null;
          example = "Qwen3TTSPipelineConfig";
          description = "Optional SGLang-Omni pipeline config class rendered into a generated YAML config.";
        };

        runtimeOverrides = mkOption {
          type = attrs;
          default = { };
          description = "Per-stage runtime overrides included in the generated pipeline config.";
        };

        allowedMediaDomains = mkOption {
          type = listOf str;
          default = [ ];
          description = "Remote media domains accepted by this instance.";
        };

        memFractionStatic = mkOption {
          type = nullOr float;
          default = null;
          description = "Optional static GPU memory fraction passed to SGLang-Omni.";
        };

        extraArgs = mkOption {
          type = listOf str;
          default = [ ];
          description = "Additional arguments appended to the `sgl-omni serve` command.";
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
  instanceName = name: "sglang-omni-${name}";

  pipelineConfigFor = name: instance:
    yamlFormat.generate "sglang-omni-${name}.yaml" (
      {
        config_cls = instance.pipelineConfigClass;
        model_path = instance.modelPath;
      }
      // optionalAttrs (instance.runtimeOverrides != { }) {
        runtime_overrides = instance.runtimeOverrides;
      }
    );

  execStartFor = name: instance:
    lib.escapeShellArgs (
      [
        (lib.getExe instance.package)
        "serve"
        "--model-path"
        instance.modelPath
      ]
      ++ optionals (instance.pipelineConfigClass != null) [
        "--config"
        (pipelineConfigFor name instance)
      ]
      ++ [
        "--host"
        instance.address
        "--port"
        (toString instance.port)
      ]
      ++ concatMap
        (domain: [
          "--allowed-media-domain"
          domain
        ])
        instance.allowedMediaDomains
      ++ optionals (instance.memFractionStatic != null) [
        "--mem-fraction-static"
        (toString instance.memFractionStatic)
      ]
      ++ instance.extraArgs
    );

  instanceAssertions = name: instance: [
    {
      assertion = builtins.match "^[a-z0-9][a-z0-9_-]*$" name != null;
      message = "services.sglang-omni.instances.${name}: instance names may contain lowercase letters, digits, underscores, and hyphens.";
    }
    {
      assertion = instance.runtimeOverrides == { } || instance.pipelineConfigClass != null;
      message = "services.sglang-omni.instances.${name}.runtimeOverrides requires pipelineConfigClass.";
    }
    {
      assertion =
        instance.memFractionStatic == null
        || (instance.memFractionStatic > 0.0 && instance.memFractionStatic <= 1.0);
      message = "services.sglang-omni.instances.${name}.memFractionStatic must be greater than 0 and at most 1.";
    }
  ];
in
{
  options.services.sglang-omni = {
    enable = mkEnableOption "multi-instance SGLang-Omni servers";

    package = mkOption {
      type = package;
      default = pkgs.sglang-omni;
      defaultText = literalExpression "pkgs.sglang-omni";
      description = "Default SGLang-Omni package for all instances.";
    };

    user = mkOption {
      type = str;
      default = "sglang-omni";
      description = "User account under which all SGLang-Omni instances run.";
    };

    group = mkOption {
      type = str;
      default = "sglang-omni";
      description = "Group under which all SGLang-Omni instances run.";
    };

    createUser = mkOption {
      type = bool;
      default = true;
      description = "Whether to create the configured service user and group.";
    };

    supplementaryGroups = mkOption {
      type = listOf str;
      default = [
        "video"
        "render"
      ];
      description = "Supplementary groups used when creating the service user.";
    };

    homeDir = mkOption {
      type = path;
      default = "/var/lib/sglang-omni";
      description = "HOME and working directory shared by all SGLang-Omni instances.";
    };

    cacheDir = mkOption {
      type = nullOr path;
      default = "/var/cache/sglang-omni";
      description = "Optional XDG cache directory shared by all instances.";
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
      description = "Named SGLang-Omni server instances.";
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
        message = "Enabled services.sglang-omni instances must use distinct ports.";
      }
    ] ++ concatMap (name: instanceAssertions name enabledInstances.${name}) (attrNames enabledInstances);

    users.users.${cfg.user} = mkIf cfg.createUser {
      inherit (cfg) group;
      extraGroups = cfg.supplementaryGroups;
      home = cfg.homeDir;
      isSystemUser = true;
    };
    users.groups.${cfg.group} = mkIf cfg.createUser { };

    systemd.tmpfiles.rules = optionals cfg.createUser (
      [
        "d ${toString cfg.homeDir} 0750 ${cfg.user} ${cfg.group} -"
      ]
      ++ optionals (cfg.cacheDir != null) [
        "d ${toString cfg.cacheDir} 0750 ${cfg.user} ${cfg.group} -"
      ]
    );

    systemd.services = mapAttrs'
      (
        name: instance:
          let
            environmentFiles = cfg.environmentFiles ++ instance.environmentFiles;
          in
          nameValuePair (instanceName name) {
            description = "SGLang-Omni server instance ${name}";
            documentation = [ "https://github.com/sgl-project/sglang-omni" ];
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];
            environment = {
              HOME = toString cfg.homeDir;
            }
            // optionalAttrs (cfg.cacheDir != null) {
              XDG_CACHE_HOME = toString cfg.cacheDir;
            }
            // cfg.extraEnvironment
            // instance.extraEnvironment;
            path = cfg.extraPackages ++ instance.extraPackages;

            serviceConfig = {
              ExecStart = execStartFor name instance;
              User = cfg.user;
              Group = cfg.group;
              WorkingDirectory = cfg.homeDir;
              Restart = "on-failure";
              RestartSec = 10;
              ReadWritePaths = [ cfg.homeDir ] ++ optionals (cfg.cacheDir != null) [ cfg.cacheDir ];
              LimitNOFILE = 1048576;
              NoNewPrivileges = true;
              PrivateTmp = true;
              ProtectHome = !(hasPrefix "/home/" (toString cfg.homeDir));
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
