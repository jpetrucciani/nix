{ lib, flake, machine-name, pkgs, config, modulesPath, ... }:
with lib;
let
  nixos-wsl = (import (fetchTarball {
    url = "https://github.com/nix-community/NixOS-WSL/archive/f3b6f6b04728416c64fc5ef52199fd9b9843c47d.tar.gz";
    sha256 = "12lambwrd2s6jgi1b3vlfpmswf79l9g3hnjdq2ilgjshm5534a7v";
  })).outputs;
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
    nixos-wsl.nixosModules.wsl
  ];

  boot.tmp.useTmpfs = true;

  environment.etc."nixpkgs-path".source = common.pkgs.path;

  # cuda stuff?
  environment.noXlibs = false;
  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
    nvidia-docker
    (pkgs.writeShellScriptBin "_invokeai" ''
      nix run github:nixified-ai/flake#invokeai-nvidia -- --web --host 0.0.0.0
    '')
    (pkgs.writeShellScriptBin "_koboldai" ''
      nix run github:nixified-ai/flake#koboldai-nvidia -- --host
    '')
  ];
  environment.variables = with pkgs; {
    NIX_HOST = hostname;
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
    _CUDA_PATH = CUDA_PATH;
    _CUDA_LDPATH = CUDA_LDPATH;
    XLA_FLAGS = "--xla_gpu_cuda_data_dir=${CUDA_PATH}";
    XLA_TARGET = cudaTarget;
    EXLA_TARGET = cudaTarget;
  };

  home-manager.users.jacobi = common.jacobi;
  wsl = {
    enable = true;
    defaultUser = "jacobi";
    startMenuLaunchers = true;
    wslConf.automount.root = "/mnt";

    # Enable native Docker support
    # docker-native.enable = true;
  };

  networking.hostName = hostname;
  nix = common.nix // {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/jacobi/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  programs.command-not-found.enable = false;

  security.sudo = common.security.sudo;
  system.stateVersion = "22.05";
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
    enableNvidia = true;
  };

  systemd.services.docker.serviceConfig.EnvironmentFile = "/etc/default/docker";
  systemd.services.docker.environment.CUDA_PATH = CUDA_PATH;
  systemd.services.docker.environment.LD_LIBRARY_PATH = CUDA_LDPATH;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
}
