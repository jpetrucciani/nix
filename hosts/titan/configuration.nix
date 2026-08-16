{ config, flake, machine-name, pkgs, ... }:
let
  inherit (flake.inputs) nixos-hardware;
  hostname = "titan";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
  yamlFormat = pkgs.formats.yaml { };
  speechServers = {
    tts = {
      modelPath = "Qwen/Qwen3-TTS-12Hz-1.7B-Base";
      pipelineConfigClass = "Qwen3TTSPipelineConfig";
      allowedMediaDomains = [
        "huggingface.co"
        "cas-bridge.xethub.hf.co"
      ];
      port = 8011;
      memFractionStatic = 0.5;
      extraEnv = { CUDA_VISIBLE_DEVICES = "1"; };
    };
    # stt = {
    #   modelPath = "Qwen/Qwen3-ASR-1.7B";
    #   port = 8012;
    #   memFractionStatic = 0.5;
    #   extraEnv = { CUDA_VISIBLE_DEVICES = "1"; };
    # };
  };
  mkSpeechService = name:
    { modelPath
    , port
    , memFractionStatic ? null
    , pipelineConfigClass ? null
    , runtimeOverrides ? { }
    , allowedMediaDomains ? [ ]
    , extraEnv ? { }
    }:
    let
      pipelineConfig = yamlFormat.generate "sglang-omni-${name}.yaml" ({
        config_cls = pipelineConfigClass;
        model_path = modelPath;
      } // pkgs.lib.optionalAttrs (runtimeOverrides != { }) {
        runtime_overrides = runtimeOverrides;
      });
      arguments = [
        (pkgs.lib.getExe pkgs.sglang-omni)
        "serve"
        "--model-path"
        modelPath
      ]
      ++ pkgs.lib.optionals (pipelineConfigClass != null) [
        "--config"
        pipelineConfig
      ]
      ++ pkgs.lib.concatMap
        (domain: [
          "--allowed-media-domain"
          domain
        ])
        allowedMediaDomains
      ++ [
        "--port"
        (toString port)
      ]
      ++ pkgs.lib.optionals (memFractionStatic != null) [
        "--mem-fraction-static"
        (toString memFractionStatic)
      ];
    in
    {
      description = "SGLang-Omni ${pkgs.lib.toUpper name} server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        HOME = "/home/jacobi";
      } // extraEnv;
      path = [ config.hardware.nvidia.package.bin ];

      serviceConfig = {
        ExecStart = pkgs.lib.escapeShellArgs arguments;
        Restart = "on-failure";
        RestartSec = 10;
        User = "jacobi";
      };
    };
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./hardware-configuration.nix
    ../modules/servers/ace-step.nix
  ] ++ (with nixos-hardware.nixosModules; [
    common-cpu-amd
    common-cpu-amd-pstate
    common-pc
    common-pc-ssd
  ]);

  inherit (common) zramSwap swapDevices;

  nix = common.nix-cuda // {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/jacobi/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  home-manager.users.jacobi = common.jacobi;

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 3;
      };
      efi.canTouchEfiVariables = true;
    };
    kernel.sysctl = { } // common.sysctl_opts;
    tmp.useTmpfs = true;
  };

  environment = {
    variables = {
      NIX_HOST = hostname;
      NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
    };
    systemPackages = with pkgs; [
      cudaPackages.cudatoolkit
      nvidia-docker
      nvtopPackages.nvidia
    ];
  };

  time.timeZone = common.timeZone;

  networking = {
    hostId = "1e35326f"; # copied from first 8 chars of /etc/machine-id - https://discourse.nixos.org/t/how-to-set-the-hostid-when-migrating-to-flakes/25607
    hostName = hostname;
    useDHCP = true;
    interfaces.enp5s0.useDHCP = true;
    firewall.enable = false;
  };

  users = {
    mutableUsers = false;
    users = {
      root.hashedPassword = "!";
      jacobi = {
        inherit (common) extraGroups;
        isNormalUser = true;
        hashedPasswordFile = "/etc/passwordFile-jacobi";
        openssh.authorizedKeys.keys = with common.pubkeys; usual;
      };
    };
  };

  services = {
    xserver.videoDrivers = [ "nvidia" ];
    ace-step = {
      enable = true;
      address = "0.0.0.0";
      port = 8012;
      gpuDevice = "0";
      downloadModels = true;
      loadModelsAtStartup = true;
      languageModel = {
        enable = true;
        model = "acestep-5Hz-lm-1.7B";
        backend = "vllm";
      };
    };
    prometheus.exporters = common.templates.prometheus_exporters { };
    qdrant = {
      enable = false;
      settings = {
        service = {
          host = "0.0.0.0";
        };
      };
    };
    caddy = {
      enable = true;
      package = pkgs.zaddy;
      email = common.emails.personal;
      globalConfig = ''
        auto_https off
        http_port 80
      '';
      extraConfig = ''
        (TAILSCALE) {
          @tailscale not remote_ip 127.0.0.1 100.64.0.0/10
          respond @tailscale "kek" 403
        }
      '';
      virtualHosts = { };
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      extensions = with pkgs.postgresql16Packages; [ pgvector ];
      enableTCPIP = true;
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
        host all all 127.0.0.1/32 trust
        host all all ::1/128 trust
        host all all 100.64.0.0/10 trust
      '';
    };
    infinity.enable = false;
    paperless = {
      enable = false;
      address = "0.0.0.0";
      settings = {
        PAPERLESS_OCR_LANGUAGE = "eng";
      };
    };
  } // common.services;

  systemd.services = pkgs.lib.mapAttrs mkSpeechService speechServers;

  system.stateVersion = "23.11";
  security.sudo = common.security.sudo;
  programs = {
    command-not-found.enable = false;
    nix-ld.enable = true;
  };

  virtualisation =
    let
      enable_kokoro = false;
    in
    {
      docker.enable = true;
      oci-containers.containers =
        let
          kokoro_version = "v0.1.0";
          kokoro_api_port = 8880;
          kokoro_ui_port = 7860;
        in
        {
          ${if enable_kokoro then "kokoro" else null} = {
            image = "ghcr.io/remsky/kokoro-fastapi-gpu:${kokoro_version}";
            ports = [ "${toString kokoro_api_port}:8880" ];
            volumes = [ "/var/lib/kokoro/voices:/app/api/src/voices" ];
            devices = [ "nvidia.com/gpu=0" ];
            environment = {
              PYTHONPATH = "/app:/app/models";
            };
          };
          ${if enable_kokoro then "kokoro-ui" else null} = {
            image = "ghcr.io/remsky/kokoro-fastapi-ui:${kokoro_version}";
            ports = [ "${toString kokoro_ui_port}:7860" ];
            volumes = [ "/var/lib/kokoro/data:/app/ui/data" ];
            environment = {
              PYTHONUNBUFFERED = "1";
              DISABLE_LOCAL_SAVING = "false";
            };
            extraOptions = [ "--add-host=kokoro-tts:10.88.0.1" ];
          };
        };
    };
  hardware = {
    nvidia = {
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      nvidiaPersistenced = true;
    };
    nvidia-container-toolkit.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
