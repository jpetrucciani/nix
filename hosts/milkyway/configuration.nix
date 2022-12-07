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

  home-manager.users.jacobi = common.jacobi;
  nixpkgs.pkgs = common.pinned;
  environment.etc."nixpkgs-path".source = common.pinned.path;
  environment.variables = {
    NIX_HOST = hostname;
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
  };

  time.timeZone = common.timeZone;

  networking.hostName = hostname;
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [ ];

  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = "jacobi";
    startMenuLaunchers = true;

    # Enable native Docker support
    # docker-native.enable = true;
  };

  nix = common.nix // {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/jacobi/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  system.stateVersion = "22.05";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
