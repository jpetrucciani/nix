{ lib, flake, machine-name, pkgs, config, modulesPath, ... }:
let
  hostname = "milkyway";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
  cuda = pkgs.cudaPackages.cudatoolkit;
  cudaTarget = "cuda114";
  WSL_MAGIC = "/usr/lib/wsl/lib";
  CUDA_PATH = cuda.outPath;
  CUDA_LDPATH = "${
      lib.concatStringsSep ":" [
        WSL_MAGIC
        "/run/opengl-drivers/lib"
        "/run/opengl-drivers-32/lib"
        "${cuda}/lib"
        "${pkgs.cudaPackages.cudnn}/lib"
      ]
    }:${
      lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib cuda.lib ]
    }";
in
{
  imports = [
    "${common.home-manager}/nixos"
    "${modulesPath}/profiles/minimal.nix"
    flake.inputs.nixos-wsl.nixosModules.wsl
  ];

  boot.tmp.useTmpfs = true;

  environment = {
    etc."nixpkgs-path".source = common.pkgs.path;
    # cuda stuff?
    noXlibs = false;
    systemPackages = with pkgs; [
      cudaPackages.cudatoolkit
      cudaPackages.cudnn
      nvidia-docker
    ];
    variables = {
      NIX_HOST = hostname;
      NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
      _CUDA_PATH = CUDA_PATH;
      _CUDA_LDPATH = CUDA_LDPATH;
      XLA_FLAGS = "--xla_gpu_cuda_data_dir=${CUDA_PATH}";
      XLA_TARGET = cudaTarget;
      EXLA_TARGET = cudaTarget;
    };
  };

  home-manager.users.jacobi = common.jacobi;
  wsl = {
    enable = true;
    defaultUser = "jacobi";
    startMenuLaunchers = true;
    wslConf.automount.root = "/mnt";
    nativeSystemd = true;

    # Enable native Docker support
    # docker-native.enable = true;
  };

  networking.hostName = hostname;
  nix = common.nix-cuda // {
    nixPath = [
      "nixpkgs=/etc/nixpkgs-path"
      "nixos-config=/home/jacobi/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
  programs.command-not-found.enable = false;

  security.sudo = common.security.sudo;
  system.stateVersion = "23.11";
  time.timeZone = common.timeZone;

  users.users.jacobi = {
    isNormalUser = true;
    description = "jacobi";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    openssh.authorizedKeys.keys = with common.pubkeys; [
      m1max
      nix-m1max
    ] ++ usual;
  };

  services = {
    xserver.videoDrivers = [ "nvidia" ];
  } // common.services;

  virtualisation.docker = {
    enable = true;
  };

  hardware = {
    opengl = {
      enable = true;
      driSupport32Bit = true;
    };
    nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  fileSystems."/mnt/jupiter" = {
    device = "100.84.224.73:/volume1/network";
    fsType = "nfs";
    options = [
      "nfsvers=4.1"
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };
}
