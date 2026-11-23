{ config, lib, pkgs, utils, ... }:
let
  inherit (lib) getExe getExe' mkEnableOption mkIf mkOption mkPackageOption optional types;
  cfg = config.services.hyperinkling;
  name = "hyperinkling";
  docker = getExe config.virtualisation.docker.package;
  runtimeDir = "/run/${name}";
  cidFile = "${runtimeDir}/container.cid";
  listenAddress = if lib.hasInfix ":" cfg.address then "[${cfg.address}]" else cfg.address;
  flag = value: if value then "1" else "0";
  env = cfg.extraEnvironment // {
    MODEL = "/model";
    HOST = "0.0.0.0";
    PORT = "8000";
    VLLM_HOST_IP = "127.0.0.1";
    ENV_FILE = "";
    HF_HUB_OFFLINE = "1";
    TRANSFORMERS_OFFLINE = "1";
    SERVED_NAME = cfg.modelName;
    SERVED_ALIASES = lib.concatStringsSep " " cfg.modelAliases;
    MAX_LEN = if cfg.contextSize == null then "auto" else toString cfg.contextSize;
    MAX_SEQS = toString cfg.parallel;
    NBT = toString cfg.prefillChunkSize;
    GPU_UTIL = toString cfg.gpuMemoryUtilization;
    KV_DTYPE = cfg.kvCacheType;
    KV_OFFLOAD_GB = toString cfg.cpuCacheGiB;
    ASYNC = flag cfg.asyncScheduling;
    SPEC = if cfg.speculation.enable then "dspark" else "off";
    HYPERINKLING_SPEC_ADAPTIVE = lib.concatMapStringsSep "," toString cfg.speculation.adaptiveDraftTokens;
    HYPERINKLING_LOOKUP = flag cfg.speculation.contextLookup;
    IMAGES = toString cfg.vision.maxImages;
    IMAGE_MAX_W = toString cfg.vision.maxWidth;
    IMAGE_MAX_H = toString cfg.vision.maxHeight;
    MM_CACHE_GB = toString cfg.vision.processorCacheGiB;
    ENCODER_CACHE = toString cfg.vision.encoderCacheTokens;
    HYPERINKLING_VISION_HOST = flag cfg.vision.weightsOnHost;
    EXTRA_ARGS = lib.concatStringsSep " " (
      optional cfg.enablePromptTokensDetails "--enable-prompt-tokens-details"
        ++ optional (cfg.extraEnvironment ? EXTRA_ARGS) cfg.extraEnvironment.EXTRA_ARGS
    );
  };
  runArgs = [
    "--name=${name}"
    "--cidfile=${cidFile}"
    "--device=nvidia.com/gpu=${cfg.gpuDevice}"
    "--publish=${listenAddress}:${toString cfg.port}:8000"
    "--cap-drop=ALL"
    "--security-opt=no-new-privileges=true"
    "--shm-size=${toString cfg.sharedMemoryGiB}g"
    "--mount=type=bind,src=${cfg.modelPath},dst=/model,readonly"
    "--mount=type=bind,src=/var/lib/${name},dst=/cache"
  ] ++ optional (cfg.memoryLimitGiB != null) "--memory=${toString cfg.memoryLimitGiB}g"
  ++ optional (cfg.environmentFile != null) "--env-file=${cfg.environmentFile}"
  ++ lib.mapAttrsToList (key: value: "--env=${key}=${value}") env;
  waitForHealth = pkgs.writeShellScript "hyperinkling-wait-for-health" ''
    while true; do
      if [[ -s ${cidFile} ]] && ${docker} exec "$(<${cidFile})" python3 -c \
        'import urllib.request; urllib.request.urlopen("http://127.0.0.1:8000/health", timeout=1).close()' >/dev/null 2>&1; then
        exit 0
      fi
      ${getExe' pkgs.coreutils "sleep"} 2
    done
  '';
  # A Docker run may fail before there is a container. Stop only the instance this unit created.
  stop = pkgs.writeShellScript "hyperinkling-stop" ''
    if [[ -s ${cidFile} ]]; then
      cid="$(<${cidFile})"
      if [[ "$(${docker} inspect --format '{{.State.Running}}' "$cid" 2>/dev/null)" == true ]]; then
        exec ${docker} stop --time 15 "$cid"
      fi
    fi
  '';
in
{
  options.services.hyperinkling = {
    enable = mkEnableOption "HyperInkling's OpenAI-compatible Inkling 2 Mini server";
    package = mkPackageOption pkgs "hyperinkling" { };
    modelPath = mkOption {
      type = types.strMatching "/[^,]+";
      example = "/srv/models/inkling2-hyperinkling";
      description = "Absolute path to the local HyperInkling GPTQ checkpoint directory. It is mounted read-only.";
    };
    modelName = mkOption {
      type = types.nonEmptyStr;
      default = "inkling-2-mini";
      description = "Primary model ID exposed by the API.";
    };
    modelAliases = mkOption {
      type = types.nonEmptyListOf (types.strMatching "[^[:space:]]+");
      default = [ "local" ];
      description = "Additional model IDs exposed by the upstream launcher.";
    };
    address = mkOption {
      type = types.nonEmptyStr;
      default = "127.0.0.1";
      description = "Host IPv4 or IPv6 address on which Docker publishes the API.";
    };
    port = mkOption {
      type = types.port;
      default = 8021;
      description = "Host port for the API.";
    };
    gpuDevice = mkOption {
      type = types.strMatching "([0-9]+|GPU-[0-9a-fA-F-]+)";
      default = "0";
      description = "Index or UUID of a single NVIDIA sm_86 GPU available through CDI.";
    };
    contextSize = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      description = "Maximum tokens per request, or null to size the limit from available VRAM at startup.";
    };
    parallel = mkOption {
      type = types.ints.positive;
      default = 6;
      description = "Maximum number of sequences scheduled concurrently.";
    };
    prefillChunkSize = mkOption {
      type = types.ints.positive;
      default = 2048;
      description = "Maximum tokens per scheduling step for chunked prefill.";
    };
    gpuMemoryUtilization = mkOption {
      type = types.numbers.between 0.01 1.0;
      default = 0.95;
      description = "Fraction of GPU memory available to vLLM.";
    };
    kvCacheType = mkOption {
      type = types.enum [ "fp8" "auto" ];
      default = "fp8";
      description = "Precision used for the GPU KV cache.";
    };
    cpuCacheGiB = mkOption {
      type = types.ints.unsigned;
      default = 0;
      description = "Size of the CPU prefix-cache tier in GiB. Zero disables CPU offload.";
    };
    sharedMemoryGiB = mkOption {
      type = types.ints.positive;
      default = 8;
      description = "Container shared memory in GiB, covering the CPU prefix cache and vision processor cache.";
    };
    memoryLimitGiB = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      description = "Optional container RAM limit in GiB, including shared memory.";
    };
    asyncScheduling = mkOption {
      type = types.bool;
      default = true;
      description = "Enable vLLM asynchronous scheduling.";
    };
    speculation = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable speculative decoding using the checkpoint's DSpark drafter.";
      };
      adaptiveDraftTokens = mkOption {
        type = types.listOf (types.ints.between 1 7);
        default = [ 2 4 7 ];
        description = "Candidate draft lengths for adaptive verification. An empty list uses the upstream fixed schedule.";
      };
      contextLookup = mkOption {
        type = types.bool;
        default = true;
        description = "Allow DSpark to look up candidate sequences in the request context.";
      };
    };
    vision = {
      maxImages = mkOption {
        type = types.ints.unsigned;
        default = 50;
        description = "Maximum images per request. Zero disables image input.";
      };
      maxWidth = mkOption {
        type = types.ints.positive;
        default = 1040;
        description = "Width in pixels used to profile and size image input.";
      };
      maxHeight = mkOption {
        type = types.ints.positive;
        default = 1560;
        description = "Height in pixels used to profile and size image input.";
      };
      processorCacheGiB = mkOption {
        type = types.ints.unsigned;
        default = 6;
        description = "Size of the shared-memory image processor cache in GiB.";
      };
      encoderCacheTokens = mkOption {
        type = types.ints.positive;
        default = 8192;
        description = "Number of image embedding tokens retained on the GPU.";
      };
      weightsOnHost = mkEnableOption "storing vision weights in host RAM to free GPU memory";
    };
    enablePromptTokensDetails = mkOption {
      type = types.bool;
      default = true;
      description = "Include prompt and cache token details in API usage responses.";
    };
    environmentFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/run/agenix/hyperinkling-env";
      description = "Runtime Docker environment file for credentials such as VLLM_API_KEY.";
    };
    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Additional HyperInkling launcher environment variables. Typed options take precedence.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.virtualisation.docker.enable && config.hardware.nvidia-container-toolkit.enable;
        message = "services.hyperinkling requires Docker and hardware.nvidia-container-toolkit.";
      }
      {
        assertion = cfg.sharedMemoryGiB > cfg.cpuCacheGiB + cfg.vision.processorCacheGiB;
        message = "services.hyperinkling.sharedMemoryGiB must exceed the combined CPU and vision processor caches.";
      }
    ];

    systemd.services.hyperinkling = {
      description = "HyperInkling Inkling 2 Mini inference server";
      wantedBy = [ "multi-user.target" ];
      requires = [ "docker.service" "nvidia-container-toolkit-cdi-generator.service" ];
      after = [ "docker.service" "nvidia-container-toolkit-cdi-generator.service" "network-online.target" ];
      wants = [ "network-online.target" ];
      partOf = [ "docker.service" ];
      unitConfig.RequiresMountsFor = utils.escapeSystemdExecArg cfg.modelPath;
      serviceConfig = {
        Type = "exec";
        ExecStart = utils.escapeSystemdExecArgs ([ (getExe cfg.package) ] ++ runArgs);
        ExecStartPost = waitForHealth;
        ExecStop = stop;
        ExecStopPost = stop;
        Restart = "on-failure";
        RestartSec = "10s";
        TimeoutStartSec = "5min";
        TimeoutStopSec = "30s";
        StateDirectory = name;
        StateDirectoryMode = "0700";
        RuntimeDirectory = name;
        RuntimeDirectoryMode = "0700";
      };
    };
  };
}
