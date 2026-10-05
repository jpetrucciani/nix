{ config, lib, pkgs, ... }:
let
  inherit (lib) escapeShellArgs getExe literalExpression mkEnableOption mkIf mkOption optional;
  inherit (lib.types) bool enum ints numbers package path port str;
  cfg = config.services.clef-flash;
in
{
  options.services.clef-flash = {
    enable = mkEnableOption "Cloudflare Clef-Flash decision API";
    package = mkOption {
      type = package;
      default = pkgs.clef-flash-server;
      defaultText = literalExpression "pkgs.clef-flash-server";
      description = "Clef-Flash server package.";
    };
    modelPath = mkOption {
      type = path;
      default = "/var/lib/clef-flash/models/clef-flash";
      description = "Manually provisioned release directory containing the backbone, processor, and joint head.";
    };
    address = mkOption {
      type = str;
      default = "127.0.0.1";
      description = "HTTP listen address.";
    };
    port = mkOption {
      type = port;
      default = 8015;
      description = "HTTP listen port.";
    };
    gpuDevice = mkOption {
      type = str;
      default = "0";
      description = "CUDA_VISIBLE_DEVICES selector; the server uses the first visible GPU.";
    };
    quantization = mkOption {
      type = enum [ "nf4" "bf16" ];
      default = "nf4";
      description = "Backbone weight precision. The joint head remains BF16.";
    };
    maxInputTokens = mkOption {
      type = ints.positive;
      default = 16384;
      description = "Combined state and schema token limit. Oversized input is rejected without truncation.";
    };
    maxQueuedRequests = mkOption {
      type = ints.positive;
      default = 4;
      description = "Maximum waiting requests, excluding the active GPU batch.";
    };
    maxBatchSize = mkOption {
      type = ints.positive;
      default = 4;
      description = "Maximum records in one GPU batch.";
    };
    maxBatchTokens = mkOption {
      type = ints.positive;
      default = cfg.maxInputTokens;
      defaultText = literalExpression "config.services.clef-flash.maxInputTokens";
      description = "Maximum padded tokens in one GPU batch, calculated as longest input times batch size.";
    };
    batchWaitMs = mkOption {
      type = numbers.between 0 1000;
      default = 5;
      description = "Milliseconds to collect compatible requests for a batch. Set to zero with maxBatchSize = 1 to disable batching.";
    };
    openFirewall = mkOption {
      type = bool;
      default = false;
      description = "Open the HTTP port in the firewall.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.maxBatchTokens >= cfg.maxInputTokens;
        message = "services.clef-flash.maxBatchTokens must cover services.clef-flash.maxInputTokens.";
      }
    ];
    users.users.clef-flash = {
      isSystemUser = true;
      group = "clef-flash";
      extraGroups = [ "video" "render" ];
    };
    users.groups.clef-flash = { };
    systemd.tmpfiles.rules = [
      "d /var/lib/clef-flash/models 0750 clef-flash clef-flash -"
    ];
    systemd.services.clef-flash = {
      description = "Cloudflare Clef-Flash decision API";
      documentation = [
        "https://github.com/jpetrucciani/clef-flash-server#readme"
        "https://huggingface.co/Cloudflare/clef-flash"
      ];
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment = {
        CUDA_VISIBLE_DEVICES = cfg.gpuDevice;
        HOME = "/var/lib/clef-flash";
        XDG_CACHE_HOME = "/var/cache/clef-flash";
        HF_HUB_OFFLINE = "1";
        PYTORCH_ALLOC_CONF = "expandable_segments:True";
      };
      serviceConfig = {
        ExecStart = escapeShellArgs [
          (getExe cfg.package)
          "--model-path"
          (toString cfg.modelPath)
          "--host"
          cfg.address
          "--port"
          (toString cfg.port)
          "--quantization"
          cfg.quantization
          "--max-input-tokens"
          (toString cfg.maxInputTokens)
          "--max-queued-requests"
          (toString cfg.maxQueuedRequests)
          "--max-batch-size"
          (toString cfg.maxBatchSize)
          "--max-batch-tokens"
          (toString cfg.maxBatchTokens)
          "--batch-wait-ms"
          (toString cfg.batchWaitMs)
        ];
        User = "clef-flash";
        Group = "clef-flash";
        StateDirectory = "clef-flash";
        CacheDirectory = "clef-flash";
        StateDirectoryMode = "0750";
        CacheDirectoryMode = "0750";
        WorkingDirectory = "/var/lib/clef-flash";
        Restart = "on-failure";
        RestartSec = 10;
        TimeoutStopSec = 300;
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
