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
      cudaPackages.cudnn
      nvidia-docker
      nvtop-nvidia
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
  } // common.services;

  system.stateVersion = "23.11";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;

  # nvidia setup?
  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
  };
  hardware = {
    nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
  };
}
