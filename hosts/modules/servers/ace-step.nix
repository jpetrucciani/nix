{ config, lib, pkgs, ... }:
let
  inherit (lib) literalExpression mkEnableOption mkIf mkOption optional optionalAttrs;
  inherit (lib.types) attrs attrsOf bool enum listOf nullOr package path port str;

  cfg = config.services.ace-step;

  environment = {
    HOME = toString cfg.dataDir;
    XDG_CACHE_HOME = toString cfg.cacheDir;
    ACESTEP_PROJECT_ROOT = toString cfg.dataDir;
    ACESTEP_CHECKPOINTS_DIR = toString cfg.checkpointsDir;
    ACESTEP_TMPDIR = toString cfg.cacheDir;
    ACESTEP_DOWNLOAD_SOURCE = cfg.downloadSource;
    ACESTEP_NO_INIT = if cfg.loadModelsAtStartup then "false" else "true";
    ACESTEP_INIT_LLM = if cfg.languageModel.enable then "true" else "false";
    PYTORCH_CUDA_ALLOC_CONF = "expandable_segments:True";
  }
  // optionalAttrs (cfg.gpuDevice != null) {
    CUDA_VISIBLE_DEVICES = cfg.gpuDevice;
  }
  // optionalAttrs cfg.languageModel.enable {
    ACESTEP_LM_MODEL_PATH = cfg.languageModel.model;
    ACESTEP_LM_BACKEND = cfg.languageModel.backend;
  }
  // cfg.extraEnvironment;

  serviceConfig = {
    User = cfg.user;
    Group = cfg.group;
    WorkingDirectory = cfg.dataDir;
    Restart = "on-failure";
    RestartSec = 10;
    TimeoutStartSec = "15min";
    ReadWritePaths = [
      cfg.dataDir
      cfg.cacheDir
    ];
    LimitNOFILE = 1048576;
    NoNewPrivileges = true;
    PrivateTmp = true;
    ProtectHome = true;
    ProtectSystem = "strict";
    UMask = "0027";
  }
  // optionalAttrs (cfg.environmentFile != null) {
    EnvironmentFile = cfg.environmentFile;
  };

  downloadServiceName = "ace-step-models.service";
in
{
  options.services.ace-step = {
    enable = mkEnableOption "ACE-Step music generation API";

    package = mkOption {
      type = package;
      default = pkgs.ace-step;
      defaultText = literalExpression "pkgs.ace-step";
      description = "ACE-Step package to run.";
    };

    user = mkOption {
      type = str;
      default = "ace-step";
      description = "User account under which ACE-Step runs.";
    };

    group = mkOption {
      type = str;
      default = "ace-step";
      description = "Group under which ACE-Step runs.";
    };

    dataDir = mkOption {
      type = path;
      default = "/var/lib/ace-step";
      description = "Persistent ACE-Step state and generated-output directory.";
    };

    checkpointsDir = mkOption {
      type = path;
      default = "/var/lib/ace-step/checkpoints";
      description = "Persistent directory containing downloaded model checkpoints.";
    };

    cacheDir = mkOption {
      type = path;
      default = "/var/cache/ace-step";
      description = "Writable cache directory for ACE-Step, Triton, and TorchInductor.";
    };

    address = mkOption {
      type = str;
      default = "127.0.0.1";
      description = "Address on which the API server listens.";
    };

    port = mkOption {
      type = port;
      default = 8001;
      description = "Port on which the API server listens.";
    };

    gpuDevice = mkOption {
      type = nullOr str;
      default = null;
      example = "0";
      description = ''
        CUDA device selector exposed to ACE-Step through CUDA_VISIBLE_DEVICES.
        Leave null to use the process environment's default device visibility.
      '';
    };

    gpuGroups = mkOption {
      type = listOf str;
      default = [
        "video"
        "render"
      ];
      description = "Supplementary groups granting the service access to GPU device nodes.";
    };

    downloadModels = mkOption {
      type = bool;
      default = true;
      description = ''
        Download the main ACE-Step checkpoint bundle before starting the API.
        Existing model files are reused.
      '';
    };

    downloadSource = mkOption {
      type = enum [
        "auto"
        "huggingface"
        "modelscope"
      ];
      default = "auto";
      description = "Preferred source for model downloads performed by the API.";
    };

    loadModelsAtStartup = mkOption {
      type = bool;
      default = true;
      description = "Load model weights during service startup instead of on the first request.";
    };

    languageModel = {
      enable = mkOption {
        type = bool;
        default = true;
        description = "Load the language-model planner used by thinking-mode generations.";
      };

      model = mkOption {
        type = str;
        default = "acestep-5Hz-lm-1.7B";
        description = "Language-model checkpoint name or path.";
      };

      backend = mkOption {
        type = enum [
          "vllm"
          "pt"
          "mlx"
        ];
        default = "vllm";
        description = "Inference backend for the language-model planner.";
      };
    };

    environmentFile = mkOption {
      type = nullOr path;
      default = null;
      example = "/run/agenix/ace-step-env";
      description = ''
        Optional environment file for secrets such as ACESTEP_API_KEY or
        HF_TOKEN. Do not put secret values directly in the Nix configuration.
      '';
    };

    extraEnvironment = mkOption {
      type = attrsOf str;
      default = { };
      example = literalExpression ''
        {
          ACESTEP_API_WORKERS = "1";
        }
      '';
      description = "Additional environment variables for model download and API services.";
    };

    extraArgs = mkOption {
      type = listOf str;
      default = [ ];
      description = "Additional arguments passed to `acestep-api`.";
    };

    openFirewall = mkEnableOption "the firewall port for the ACE-Step API";

    serviceConfig = mkOption {
      type = attrs;
      default = { };
      description = "Extra systemd serviceConfig settings for ace-step.service.";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      inherit (cfg) group;
      home = cfg.dataDir;
      isSystemUser = true;
      extraGroups = cfg.gpuGroups;
    };
    users.groups.${cfg.group} = { };

    systemd.tmpfiles.rules = [
      "d ${toString cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.checkpointsDir} 0750 ${cfg.user} ${cfg.group} -"
      "d ${toString cfg.cacheDir} 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.ace-step-models = mkIf cfg.downloadModels {
      description = "Download ACE-Step model checkpoints";
      documentation = [ "https://github.com/ace-step/ACE-Step-1.5" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      inherit environment;

      serviceConfig = serviceConfig // {
        Type = "oneshot";
        ExecStart = lib.escapeShellArgs [
          (lib.getExe' cfg.package "acestep-download")
          "--dir"
          (toString cfg.checkpointsDir)
        ];
        RemainAfterExit = true;
        Restart = "on-failure";
        TimeoutStartSec = "infinity";
      };
    };

    systemd.services.ace-step = {
      description = "ACE-Step music generation API";
      documentation = [ "https://github.com/ace-step/ACE-Step-1.5/blob/main/docs/en/API.md" ];
      wants = [ "network-online.target" ];
      requires = optional cfg.downloadModels downloadServiceName;
      after = [ "network-online.target" ] ++ optional cfg.downloadModels downloadServiceName;
      wantedBy = [ "multi-user.target" ];
      inherit environment;

      serviceConfig = serviceConfig // {
        ExecStart = lib.escapeShellArgs (
          [
            (lib.getExe cfg.package)
            "--host"
            cfg.address
            "--port"
            (toString cfg.port)
          ]
          ++ cfg.extraArgs
        );
      } // cfg.serviceConfig;
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
