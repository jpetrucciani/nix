{ config, lib, pkgs, ... }:
let
  inherit (lib) escapeShellArgs getExe literalExpression mkEnableOption mkIf mkOption optional;
  inherit (lib.types) addCheck attrsOf bool ints listOf numbers package path port str;
  cfg = config.services.h2o-lightning-4b;
in
{
  options.services.h2o-lightning-4b = {
    enable = mkEnableOption "H2O-Lightning-4B decision API";
    package = mkOption {
      type = package;
      default = pkgs.h2o-lightning-4b;
      defaultText = literalExpression "pkgs.h2o-lightning-4b";
      description = "H2O-Lightning-4B wrapper package, including its pinned shim and serving configuration.";
    };
    address = mkOption {
      type = str;
      default = "127.0.0.1";
      description = "Decision API listen address. The vLLM backend always listens on loopback.";
    };
    port = mkOption {
      type = port;
      default = 8741;
      description = "Decision API listen port.";
    };
    vllmPort = mkOption {
      type = port;
      default = 8000;
      description = "Private vLLM backend port. Must differ from the decision API port.";
    };
    gpuDevice = mkOption {
      type = str;
      default = "0";
      description = "CUDA_VISIBLE_DEVICES selector for the vLLM backend.";
    };
    gpuMemoryUtilization = mkOption {
      type = addCheck (numbers.between 0 1) (value: value > 0);
      default = 0.9;
      description = "Fraction of GPU memory reserved by vLLM, greater than zero and at most one.";
    };
    maxModelLen = mkOption {
      type = ints.positive;
      default = 40960;
      description = "vLLM context token limit.";
    };
    model = mkOption {
      type = str;
      default = cfg.package.modelId;
      defaultText = literalExpression "config.services.h2o-lightning-4b.package.modelId";
      description = "Hugging Face model ID or a local model directory readable by the service user.";
    };
    revision = mkOption {
      type = str;
      default = cfg.package.modelRev;
      defaultText = literalExpression "config.services.h2o-lightning-4b.package.modelRev";
      description = "Model revision, pinned to the package's shim and serving configuration by default.";
    };
    extraArgs = mkOption {
      type = listOf str;
      default = [ ];
      example = [ "--max-num-seqs" "4" ];
      description = "Additional vLLM arguments passed after the wrapper's -- separator.";
    };
    extraEnvironment = mkOption {
      type = attrsOf str;
      default = { };
      description = "Additional non-secret environment variables for the wrapper and vLLM backend.";
    };
    environmentFiles = mkOption {
      type = listOf path;
      default = [ ];
      example = [ "/run/agenix/h2o-lightning-4b-env" ];
      description = "Runtime environment files for secrets such as HF_TOKEN.";
    };
    openFirewall = mkOption {
      type = bool;
      default = false;
      description = "Open the decision API port in the firewall. The backend port remains private.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.port != cfg.vllmPort;
        message = "services.h2o-lightning-4b.port and vllmPort must differ.";
      }
    ];
    users.users.h2o-lightning-4b = {
      isSystemUser = true;
      group = "h2o-lightning-4b";
      home = "/var/lib/h2o-lightning-4b";
      extraGroups = [ "video" "render" ];
    };
    users.groups.h2o-lightning-4b = { };
    systemd.services.h2o-lightning-4b = {
      description = "H2O-Lightning-4B decision API";
      documentation = [ "https://huggingface.co/h2oai/h2o-lightning-4b" ];
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      environment = {
        CUDA_VISIBLE_DEVICES = cfg.gpuDevice;
        HOME = "/var/lib/h2o-lightning-4b";
        HF_HOME = "/var/lib/h2o-lightning-4b/huggingface";
        XDG_CACHE_HOME = "/var/cache/h2o-lightning-4b";
      } // cfg.extraEnvironment;
      serviceConfig = {
        ExecStart = escapeShellArgs (
          [
            (getExe cfg.package)
            "--host"
            cfg.address
            "--port"
            (toString cfg.port)
            "--vllm-port"
            (toString cfg.vllmPort)
            "--gpu-memory-utilization"
            (toString cfg.gpuMemoryUtilization)
            "--max-model-len"
            (toString cfg.maxModelLen)
            "--model"
            cfg.model
            "--revision"
            cfg.revision
            "--"
          ] ++ cfg.extraArgs
        );
        EnvironmentFile = cfg.environmentFiles;
        User = "h2o-lightning-4b";
        Group = "h2o-lightning-4b";
        StateDirectory = "h2o-lightning-4b";
        CacheDirectory = "h2o-lightning-4b";
        StateDirectoryMode = "0750";
        CacheDirectoryMode = "0750";
        WorkingDirectory = "/var/lib/h2o-lightning-4b";
        Restart = "on-failure";
        RestartSec = 10;
        TimeoutStopSec = 300;
        LimitNOFILE = 1048576;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        UMask = "0027";
      };
    };
    networking.firewall.allowedTCPPorts = optional cfg.openFirewall cfg.port;
  };
}
