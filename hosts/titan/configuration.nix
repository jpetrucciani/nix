{ config, flake, machine-name, pkgs, ... }:
let
  inherit (flake.inputs) nixos-hardware;
  hostname = "titan";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./hardware-configuration.nix
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
      systemd-boot.enable = true;
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
      linuxPackages.nvidia_x11
    ];
  };

  time.timeZone = common.timeZone;

  networking = {
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
    promtail = common.templates.promtail { inherit hostname; };
    prometheus.exporters = common.templates.prometheus_exporters { };
    qdrant = {
      enable = true;
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
    };
    nvidia-container-toolkit.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
