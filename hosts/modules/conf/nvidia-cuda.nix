{ config, lib, pkgs, ... }:
let
  constants = import ../../constants.nix;
in
{
  nix.settings = {
    extra-substituters = lib.mkAfter [ constants.subs.nix-community.url ];
    extra-trusted-public-keys = lib.mkAfter [ constants.subs.nix-community.key ];
  };

  boot = {
    kernelModules = [ "nvidia" ];
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };

  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
    nvidia-docker
    nvtopPackages.nvidia
  ];

  programs.nix-ld.enable = lib.mkDefault true;

  services.xserver.videoDrivers = [ "nvidia" ];

  virtualisation.docker.enable = lib.mkDefault true;

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
