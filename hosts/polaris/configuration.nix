{ config, flake, machine-name, pkgs, ... }:
let
  inherit (flake.inputs) nixos-hardware;
  hostname = "polaris";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
  # NixOS has no ld.so.cache; stub for tools that shell out to /sbin/ldconfig -p
  ldconfigShim = pkgs.writeShellScript "ldconfig-shim" ''
    exit 0
  '';
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./hardware-configuration.nix
    ../modules/conf/nvidia-smi-workaround.nix
    ../modules/servers/hermes-agent.nix
    ../modules/servers/hyperinkling.nix
    ../modules/servers/strata.nix
  ] ++ (with nixos-hardware.nixosModules; [
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
    zfs = {
      extraPools = [ "zroot" ];
      forceImportRoot = false;
      forceImportAll = false;
    };
  };

  systemd.tmpfiles.rules = [
    "d /sbin 0755 root root - -"
    "L+ /sbin/ldconfig 0755 root root - ${ldconfigShim}"
  ];

  systemd.services = {
    qwen-image = {
      description = "Polaris qwen-image";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = [ config.nix.package pkgs.bash ];
      environment.HOME = "/home/jacobi";
      serviceConfig = {
        User = "jacobi";
        WorkingDirectory = "/home/jacobi/svc/prod";
        ExecStart = "${pkgs.direnv}/bin/direnv exec . run_qwen-image";
        Restart = "always";
        RestartSec = 10;
      };
    };
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
    hostId = "9ff007b2"; # copied from first 8 chars of /etc/machine-id - https://discourse.nixos.org/t/how-to-set-the-hostid-when-migrating-to-flakes/25607
    hostName = hostname;
    useDHCP = true;
    interfaces.enp4s0f2.useDHCP = true;
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
    # strata = {
    #   enable = true;
    #   user = "jacobi";
    #   cudaArchitectures = [ "86" ];
    #   # GPU 1 serves Qwen-Image. Keep the experts and long-context KV in system RAM.
    #   gpuDevices = [ 0 ];
    #   family = "qwen";
    #   model = "IQ3_S";
    #   contextSize = 262144;
    #   kvCacheType = "int8";
    #   kvStreaming = "on";
    #   lowRam = "off";
    #   vramReserveMiB = 2048;
    #   mtp = true;
    #   address = "0.0.0.0";
    #   port = 8021;
    # };
    hyperinkling = {
      enable = true;
      # GPU 1 serves Qwen-Image.
      gpuDevice = "0";
      modelPath = "/srv/models/inkling2-hyperinkling-92de097";
      parallel = 8;
      cpuCacheGiB = 12;
      sharedMemoryGiB = 24;
      memoryLimitGiB = 64;
      address = "0.0.0.0";
      port = 8021;
    };
    hermes-agent = {
      enable = true;
      instances.ava = {
        uid = 32001;
        enableNix = true;
        # SLATE_TOKEN comes from the instance's .env; hermes expands it when it loads this.
        settings = {
          mcp_servers.slate = {
            url = "https://slate.cobi.dev/mcp";
            headers.Authorization = "Bearer \${SLATE_TOKEN}";
          };
        };
        packages = with pkgs; [
          aq
          chrome-devtools-mcp-headless
          claude-code
          codex-latest
          curl
          duckdb
          fd
          gh
          git
          glab
          jq
          mcp-grafana
          nano
          openssh
          ripgrep
          swi-prolog
          unzip
          uv
          yq-go
          zip
        ];
      };
    };
    k3s = {
      enable = true;
      role = "server";
      extraFlags = "--disable traefik --tls-san='100.65.145.59'";
    };
    prometheus.exporters = common.templates.prometheus_exporters { };
  } // common.services;

  system.stateVersion = "24.05";
  security.sudo = common.security.sudo;
  programs = {
    command-not-found.enable = false;
    nix-ld.enable = true;
  };

  virtualisation.docker.enable = true;
  hardware = {
    nvidia = {
      open = false;
      modesetting.enable = true;
      nvidiaPersistenced = true;
    };
    nvidia-container-toolkit.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
  security.pam.loginLimits = [
    { domain = "*"; item = "nofile"; type = "-"; value = "131072"; }
    { domain = "*"; item = "memlock"; type = "-"; value = "419430400"; }
  ];
}
