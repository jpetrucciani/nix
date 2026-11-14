{ config, flake, machine-name, pkgs, ... }:
let
  inherit (flake.inputs) nixos-hardware;
  hostname = "polaris";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
  strata = pkgs.strata.ampere;
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
    strata = {
      description = "Polaris Qwen3.8-Flash-Next IQ3_S (Strata)";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = [ config.hardware.nvidia.package ];
      environment = {
        HOME = "/var/lib/strata";
        STRATA_INSTALL_DIR = "/var/lib/strata";
        CUDA_VISIBLE_DEVICES = "0";
        PYTHONUNBUFFERED = "1";
      };
      # Keep the experts and long-context KV in system RAM; GPU 1 serves Qwen-Image.
      preStart = ''
        ${strata}/bin/strata-prepare \
          --yes --family qwen --model IQ3_S \
          --gpu 0 --context 262144 --kv int8 --kv-streaming on \
          --low-ram off --vram-reserve-mib 2048 --mtp on \
          --host 0.0.0.0 --port 8021 --no-browser \
          --data-dir /var/lib/strata/data
      '';
      serviceConfig = {
        User = "jacobi";
        StateDirectory = "strata";
        WorkingDirectory = "/var/lib/strata";
        ExecStart = "${strata}/bin/strata serve --config /var/lib/strata/strata-iq3_s.json --host 0.0.0.0 --port 8021";
        Restart = "on-failure";
        RestartSec = 10;
        # The first start downloads and prepares the model outside the Nix store.
        TimeoutStartSec = "infinity";
        LimitMEMLOCK = "infinity";
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
    hermes-agent = {
      enable = true;
      instances.ava = {
        uid = 32001;
        enableNix = true;
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
