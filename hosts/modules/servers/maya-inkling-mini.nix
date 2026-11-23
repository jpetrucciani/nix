# Runs the Maya Inkling 2 Mini API server with local model weights and optional vision or DSpark.
{ config, lib, pkgs, utils, ... }:
let
  inherit (lib) escapeShellArgs getExe' literalExpression mkDefault mkEnableOption mkIf mkOption optional optionalAttrs optionals;
  inherit (lib.types) attrsOf bool enum ints listOf nonEmptyListOf nonEmptyStr nullOr package pathWith port str strMatching;

  cfg = config.services.maya-inkling-mini;
  runtimePath = pathWith { absolute = true; inStore = false; };
  stateDir = "/var/lib/${cfg.stateDirectory}";
  runtimeDir = "/run/maya-inkling-mini";
  tokenizer = if cfg.tokenizerDir == null then "${runtimeDir}/tokenizer" else cfg.tokenizerDir;
  visionEnabled = cfg.vision.mmprojPath != null;
  requiredFiles = [ cfg.modelPath ]
    ++ optional (cfg.drafterPath != null) cfg.drafterPath
    ++ optional visionEnabled cfg.vision.mmprojPath;
  runConfig = pkgs.writeText "maya-inkling-mini.json" (builtins.toJSON ({
    exe = getExe' cfg.package "maya-ik2";
    args = [
      "--model"
      cfg.modelPath
      "--max-context"
      (toString cfg.contextSize)
      "--chunk"
      (toString cfg.promptChunkSize)
      "--parallel"
      (toString cfg.parallel)
    ] ++ optionals (cfg.drafterPath != null) [ "--draft" cfg.drafterPath ] ++ cfg.extraEngineArgs;
    cwd = stateDir;
    inherit tokenizer;
    model_name = cfg.modelName;
    log = "${stateDir}/maya.log";
  } // optionalAttrs visionEnabled {
    vision = {
      exe = getExe' cfg.vision.package "maya-vision";
      model = cfg.modelPath;
      mmproj = cfg.vision.mmprojPath;
      gpu = false;
    };
  }));
in
{
  options.services.maya-inkling-mini = {
    enable = mkEnableOption "Maya Inkling 2 Mini CUDA inference server";

    cudaArchitectures = mkOption {
      type = nonEmptyListOf nonEmptyStr;
      default = [ "86" ];
      example = [ "86" "89" ];
      description = "CUDA architectures compiled into the default package. The upstream benchmark uses 86 for Ampere.";
    };
    package = mkOption {
      type = package;
      default = pkgs.maya-inkling-mini.override { inherit (cfg) cudaArchitectures; };
      defaultText = literalExpression "pkgs.maya-inkling-mini.override { inherit (config.services.maya-inkling-mini) cudaArchitectures; }";
      description = "Maya package used to prepare the tokenizer and run the server.";
    };
    modelPath = mkOption {
      type = runtimePath;
      example = "/srv/models/Inkling-2-Mini-UD-Q4_K_XL.gguf";
      description = "Path to the local Unsloth Inkling 2 Mini UD-Q4_K_XL GGUF.";
    };
    modelName = mkOption {
      type = nonEmptyStr;
      default = "inkling-2-mini";
      description = "Model ID advertised by the API.";
    };
    tokenizerDir = mkOption {
      type = nullOr runtimePath;
      default = null;
      description = "Directory with an existing Maya tokenizer. By default the service extracts it from the GGUF at startup.";
    };
    contextSize = mkOption {
      type = ints.positive;
      default = 262144;
      description = "Maximum context length in tokens, including prompt and output.";
    };
    promptChunkSize = mkOption {
      type = ints.positive;
      default = 2048;
      description = "Prompt evaluation chunk size in tokens.";
    };
    kvCacheType = mkOption {
      type = enum [ "fp8" "f16" ];
      default = "fp8";
      description = "KV cache precision.";
    };
    parallel = mkOption {
      type = ints.between 1 8;
      default = 1;
      description = "Maximum simultaneous requests. Values above one enable Maya's experimental paged KV batching.";
    };
    drafterPath = mkOption {
      type = nullOr runtimePath;
      default = null;
      example = "/srv/models/mtp.safetensors";
      description = "Path to Thinking Machines' optional DSpark weights.";
    };
    draftContextSize = mkOption {
      type = ints.positive;
      default = 65536;
      description = "Context length available to the DSpark drafter.";
    };
    vision = {
      mmprojPath = mkOption {
        type = nullOr runtimePath;
        default = null;
        example = "/srv/models/mmproj-BF16.gguf";
        description = "Path to Inkling 2 Mini's image projector GGUF. Setting this enables image input with a CPU encoder.";
      };
      package = mkOption {
        type = package;
        default = cfg.package.vision;
        defaultText = literalExpression "config.services.maya-inkling-mini.package.vision";
        description = "Package providing the CPU encoder at bin/maya-vision.";
      };
    };
    gpuDevice = mkOption {
      type = nonEmptyStr;
      default = "0";
      example = "1";
      description = "Single CUDA GPU index or UUID passed through CUDA_VISIBLE_DEVICES.";
    };
    address = mkOption {
      type = nonEmptyStr;
      default = "127.0.0.1";
      description = "API listen address.";
    };
    port = mkOption {
      type = port;
      default = 18000;
      description = "API listen port.";
    };
    openFirewall = mkOption {
      type = bool;
      default = false;
      description = "Whether to open the API port in the firewall.";
    };
    user = mkOption {
      type = nonEmptyStr;
      default = "maya-inkling-mini";
      description = "Service user. The module creates the default user. A different account must already exist.";
    };
    stateDirectory = mkOption {
      type = strMatching "[A-Za-z0-9][A-Za-z0-9._-]*";
      default = "maya-inkling-mini";
      description = "Directory name under /var/lib for Maya's writable state and logs.";
    };
    extraEngineArgs = mkOption {
      type = listOf str;
      default = [ ];
      description = "Additional arguments passed to maya-ik2.";
    };
    extraServeArgs = mkOption {
      type = listOf str;
      default = [ ];
      example = [ "--idle-unload" "900" ];
      description = "Additional arguments passed to maya-serve.";
    };
    extraEnvironment = mkOption {
      type = attrsOf str;
      default = { };
      description = "Additional non-secret environment variables for Maya.";
    };
    environmentFiles = mkOption {
      type = listOf runtimePath;
      default = [ ];
      example = [ "/run/agenix/maya-inkling-mini-env" ];
      description = "Runtime environment files, for example one defining MAYA_API_KEY.";
    };
  };

  config = mkIf cfg.enable {
    users.users.maya-inkling-mini = mkIf (cfg.user == "maya-inkling-mini") {
      isSystemUser = true;
      group = "maya-inkling-mini";
      home = stateDir;
      extraGroups = [ "video" "render" ];
    };
    users.groups.maya-inkling-mini = mkIf (cfg.user == "maya-inkling-mini") { };

    networking.firewall.allowedTCPPorts = optional cfg.openFirewall cfg.port;

    systemd.services.maya-inkling-mini = {
      description = "Maya Inkling 2 Mini CUDA inference server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      unitConfig.RequiresMountsFor = map
        (path: lib.replaceStrings [ "%" ] [ "%%" ] (builtins.toJSON path))
        (requiredFiles ++ optional (cfg.tokenizerDir != null) cfg.tokenizerDir);
      path = [ config.hardware.nvidia.package ];
      environment = {
        HOME = stateDir;
        CUDA_DEVICE_ORDER = "PCI_BUS_ID";
        CUDA_VISIBLE_DEVICES = cfg.gpuDevice;
        PYTHONUNBUFFERED = "1";
        # Match upstream's resident single-GPU profile.
        IK2_KV = cfg.kvCacheType;
        IK2_GATE_TILE = "64";
        IK2_GATE_BF16 = "1";
        IK2_Q8_UNROLL = "1";
        IK2_BATCH_PREFILL = "1";
      } // optionalAttrs (cfg.drafterPath != null) {
        IK2_DRAFT_CTX = toString cfg.draftContextSize;
      } // optionalAttrs visionEnabled {
        TMPDIR = runtimeDir;
      } // cfg.extraEnvironment;

      preStart = ''
        paths=(${escapeShellArgs requiredFiles})
        for required in "''${paths[@]}"; do
          if [ ! -r "$required" ]; then
            printf 'Cannot read Maya weights at %s\n' "$required" >&2
            exit 1
          fi
        done
      '' + lib.optionalString (cfg.tokenizerDir == null) ''
        ${escapeShellArgs [ (getExe' cfg.package "maya-prepare") "--gguf" cfg.modelPath "--out" runtimeDir ]}
      '' + ''
        if [ ! -r ${lib.escapeShellArg "${tokenizer}/vocab.json"} ] || [ ! -r ${lib.escapeShellArg "${tokenizer}/chat_template.jinja"} ]; then
          printf 'Maya tokenizer files are missing in %s\n' ${lib.escapeShellArg tokenizer} >&2
          exit 1
        fi
      '';

      serviceConfig = {
        User = cfg.user;
        StateDirectory = cfg.stateDirectory;
        StateDirectoryMode = "0750";
        WorkingDirectory = stateDir;
        ExecStart = utils.escapeSystemdExecArgs ([
          (getExe' cfg.package "maya-serve")
          "--config"
          runConfig
          "--host"
          cfg.address
          "--port"
          (toString cfg.port)
        ] ++ cfg.extraServeArgs);
        EnvironmentFile = cfg.environmentFiles;
        Restart = mkDefault "on-failure";
        RestartSec = mkDefault 10;
        LimitMEMLOCK = mkDefault "infinity";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        UMask = "0027";
      } // optionalAttrs (cfg.tokenizerDir == null || visionEnabled) {
        RuntimeDirectory = "maya-inkling-mini";
        RuntimeDirectoryMode = "0750";
      };
    };
  };
}
