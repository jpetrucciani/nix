{ lib, pkgs, config, modulesPath, ... }:
with lib;
let
  nixos-wsl = (import (fetchTarball { url = "https://github.com/nix-community/NixOS-WSL/archive/main.tar.gz"; })).outputs;
  hostname = "milkyway";
  common = import ../common.nix { inherit config pkgs; };
in
{
  imports = [
    "${common.home-manager.path}/nixos"
    "${modulesPath}/profiles/minimal.nix"
    nixos-wsl.nixosModules.wsl
  ];

  environment.etc."nixpkgs-path".source = common.pinned.path;

  # cuda stuff?
  environment.noXlibs = false;
  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
  ];
  environment.variables =
    let
      cuda = pkgs.cudaPackages.cudatoolkit;
      cudnn = pkgs.cudaPackages.cudnn;
      cudaTarget = "cuda114";
    in
    with pkgs; {
      NIX_HOST = hostname;
      NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
      _CUDA_PATH = cuda.outPath;
      _CUDA_LDPATH = "${
      lib.concatStringsSep ":" [
        "/usr/lib/wsl/lib"
        "/run/opengl-drivers/lib"
        "/run/opengl-drivers-32/lib"
        "${cuda}/lib"
        "${cudnn}/lib"
      ]
    }:${
      lib.makeLibraryPath [ stdenv.cc.cc.lib cuda.lib ]
    }";
      XLA_FLAGS = "--xla_gpu_cuda_data_dir=${cuda.outPath}";
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
  nixpkgs.pkgs = common.pinned;
  nixpkgs.config.allowUnfree = true;
  programs.command-not-found.enable = false;

  security.sudo = common.security.sudo;
  system.stateVersion = "22.05";
  time.timeZone = common.timeZone;

  users.users.jacobi = {
    isNormalUser = true;
    description = "jacobi";
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = with common.pubkeys; [
      m1max
      nix-m1max
    ] ++ usual;
  };

  services = { } // common.services;

  # nvidia? not needed for cuda memes?
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.opengl.enable = true;
  # hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
}
