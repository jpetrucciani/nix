# Runs the Strata CUDA API server with optional model preparation at startup.
{ config, lib, pkgs, utils, ... }:
let
  inherit (lib) concatStringsSep escapeShellArgs getExe' literalExpression mkDefault mkEnableOption mkIf mkOption optional toLower;
  inherit (lib.types) attrsOf bool enum ints listOf nonEmptyListOf nonEmptyStr nullOr package pathWith port str strMatching;

  cfg = config.services.strata;
  nameType = strMatching "[A-Za-z0-9][A-Za-z0-9._+-]*";
  runtimePath = pathWith { absolute = true; inStore = false; };
  stateDir = "/var/lib/${cfg.stateDirectory}";
  gpuList = concatStringsSep "," (map toString cfg.gpuDevices);
  listenArgs = [ "--host" cfg.address "--port" (toString cfg.port) ];
  prepareArgs = lib.cli.toCommandLine
    (name: { option = "--${name}"; sep = null; explicitBool = false; })
    {
      yes = true;
      no-browser = true;
      backend = "cuda";
      inherit (cfg) family model;
      ${if builtins.length cfg.gpuDevices == 1 then "gpu" else "gpus"} = gpuList;
      data-dir = cfg.dataDir;
      context = cfg.contextSize;
      kv = cfg.kvCacheType;
      kv-streaming = cfg.kvStreaming;
      low-ram = cfg.lowRam;
      vram-reserve-mib = cfg.vramReserveMiB;
      mtp = if cfg.mtp == null then null else if cfg.mtp then "on" else "off";
    } ++ listenArgs;
in
{
  options.services.strata = {
    enable = mkEnableOption "Strata CUDA inference server";

    cudaArchitectures = mkOption {
      type = nonEmptyListOf nonEmptyStr;
      default = [ "86" ];
      example = [ "89" "120" ];
      description = "CUDA architectures compiled into the default package. Use 86 for Ampere, 89 for Ada, or 120 for RTX 50 series.";
    };
    package = mkOption {
      type = package;
      default = pkgs.strata.override { inherit (cfg) cudaArchitectures; };
      defaultText = literalExpression "pkgs.strata.override { inherit (config.services.strata) cudaArchitectures; }";
      description = "Strata package used to prepare and serve the model.";
    };
    address = mkOption {
      type = nonEmptyStr;
      default = "127.0.0.1";
      description = "API listen address.";
    };
    port = mkOption {
      type = port;
      default = 8080;
      description = "API listen port.";
    };
    openFirewall = mkOption {
      type = bool;
      default = false;
      description = "Whether to open the API port in the firewall.";
    };
    gpuDevices = mkOption {
      type = nonEmptyListOf ints.unsigned;
      default = [ 0 ];
      example = [ 0 2 ];
      description = "GPU indices as listed by nvidia-smi. Strata receives a multi-GPU selection when more than one index is set.";
    };
    user = mkOption {
      type = nonEmptyStr;
      default = "strata";
      description = "Service user. The module creates the default strata account. A different account must already exist.";
    };
    stateDirectory = mkOption {
      type = nameType;
      default = "strata";
      description = "Directory name under /var/lib for Strata run configs, logs, and verification state.";
    };
    dataDir = mkOption {
      type = runtimePath;
      default = "${stateDir}/data";
      defaultText = literalExpression ''"/var/lib/${config.services.strata.stateDirectory}/data"'';
      description = "Writable directory for model weights and prepared packs. An external directory or its parent must be writable by the service user.";
    };
    prepare = mkOption {
      type = bool;
      default = true;
      description = "Whether to let Strata download and prepare the selected model before serving.";
    };
    family = mkOption {
      type = nameType;
      default = "qwen";
      example = "inkling-2-mini";
      description = "Strata model family passed to preparation.";
    };
    model = mkOption {
      type = nullOr nameType;
      default = null;
      example = "IQ3_S";
      description = "Model variant passed to preparation, for example IQ3_S for qwen or SQ-20 for inkling-2-mini.";
    };
    configFile = mkOption {
      type = pathWith { absolute = true; };
      default =
        if cfg.model == null then "${stateDir}/strata.json"
        else "${stateDir}/strata-${lib.optionalString (cfg.family != "qwen") "${cfg.family}-"}${toLower cfg.model}.json";
      defaultText = literalExpression ''"/var/lib/<stateDirectory>/strata-<family tag><model>.json"'';
      description = "Run config passed to strata serve. Without a model, this defaults to strata.json under the state directory.";
    };
    contextSize = mkOption {
      type = nullOr ints.positive;
      default = null;
      example = 262144;
      description = "Model context length in tokens. The default uses Strata's model-specific choice.";
    };
    kvCacheType = mkOption {
      type = nullOr (enum [ "int8" "q4_0" "k8v4" "fp16" ]);
      default = null;
      description = "KV cache precision passed to preparation.";
    };
    kvStreaming = mkOption {
      type = nullOr (enum [ "auto" "on" "off" ]);
      default = null;
      description = "Whether to stream the KV cache from host memory.";
    };
    lowRam = mkOption {
      type = nullOr (enum [ "auto" "on" "off" "resident" "mmap" ]);
      default = null;
      description = "Expert weight placement mode passed to preparation.";
    };
    vramReserveMiB = mkOption {
      type = nullOr ints.unsigned;
      default = null;
      example = 2048;
      description = "How many MiB of VRAM the engine leaves free.";
    };
    mtp = mkOption {
      type = nullOr bool;
      default = null;
      description = "Whether to enable the MTP draft layer for models that support it.";
    };
    extraPrepareArgs = mkOption {
      type = listOf str;
      default = [ ];
      example = [ "--vision" "yes" ];
      description = "Additional arguments passed to strata-prepare.";
    };
    extraServeArgs = mkOption {
      type = listOf str;
      default = [ ];
      example = [ "--parallel" "4" ];
      description = "Additional arguments passed to strata serve.";
    };
    extraEnvironment = mkOption {
      type = attrsOf str;
      default = { };
      description = "Additional non-secret environment variables for the service.";
    };
    environmentFiles = mkOption {
      type = listOf runtimePath;
      default = [ ];
      example = [ "/run/agenix/strata-env" ];
      description = "Runtime environment files, for example one defining STRATA_API_KEY.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.prepare || cfg.model != null;
        message = "services.strata.model must be set when services.strata.prepare is enabled.";
      }
      {
        assertion = lib.unique cfg.gpuDevices == cfg.gpuDevices;
        message = "services.strata.gpuDevices must contain distinct GPU indices.";
      }
    ];

    users.users.strata = mkIf (cfg.user == "strata") {
      isSystemUser = true;
      group = "strata";
      home = stateDir;
      extraGroups = [ "video" "render" ];
    };
    users.groups.strata = mkIf (cfg.user == "strata") { };

    networking.firewall.allowedTCPPorts = optional cfg.openFirewall cfg.port;

    systemd.services.strata = {
      description = "Strata CUDA inference server";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      unitConfig.RequiresMountsFor = map
        (path: lib.replaceStrings [ "%" ] [ "%%" ] (builtins.toJSON (toString path)))
        ([ cfg.configFile ] ++ optional cfg.prepare cfg.dataDir);
      path = [ config.hardware.nvidia.package ];
      environment = {
        HOME = stateDir;
        STRATA_INSTALL_DIR = stateDir;
        CUDA_DEVICE_ORDER = "PCI_BUS_ID";
        CUDA_VISIBLE_DEVICES = gpuList;
        PYTHONUNBUFFERED = "1";
      } // cfg.extraEnvironment;
      preStart = mkIf cfg.prepare (escapeShellArgs ([ (getExe' cfg.package "strata-prepare") ] ++ prepareArgs ++ cfg.extraPrepareArgs));
      serviceConfig = {
        User = cfg.user;
        StateDirectory = cfg.stateDirectory;
        WorkingDirectory = stateDir;
        ExecStart = utils.escapeSystemdExecArgs (
          [ (getExe' cfg.package "strata") "serve" "--config" (toString cfg.configFile) ]
          ++ listenArgs ++ cfg.extraServeArgs
        );
        EnvironmentFile = cfg.environmentFiles;
        Restart = mkDefault "on-failure";
        RestartSec = mkDefault 10;
        # Model preparation can download large weights on the first start.
        TimeoutStartSec = mkDefault "infinity";
        LimitMEMLOCK = mkDefault "infinity";
      };
    };
  };
}
