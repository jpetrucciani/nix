{ config, machine-name, pkgs, ... }:
let
  hostname = "granite";
  common = import ../common.nix { inherit config machine-name pkgs; isBarebones = true; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./hardware-configuration.nix
  ];

  inherit (common) zramSwap;

  nix = common.nix // {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/jacobi/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  home-manager.users.jacobi = common.jacobi;
  nixpkgs.pkgs = common.pinned;

  boot = {
    loader = {
      grub.enable = true;
      grub.version = 2;
      grub.device = "/dev/sda";
    };
    kernel.sysctl = { } // common.sysctl_opts;
    tmp.useTmpfs = true;
  };

  environment.variables = {
    NIX_HOST = hostname;
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
  };

  time.timeZone = common.timeZone;

  networking.hostName = hostname;
  networking.extraHosts = common.extraHosts.proxmox;
  networking.firewall.enable = false;

  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";
  users.users.jacobi = {
    inherit (common) extraGroups;
    isNormalUser = true;
    passwordFile = "/etc/passwordFile-jacobi";
    openssh.authorizedKeys.keys = with common.pubkeys; [ ] ++ usual;
  };

  services = {
    nfs.server =
      let
        opts = "(rw,nohide,insecure,no_subtree_check)";
        paths = [
          "/export/granite"
          "/export/orbit"
        ];
        nfsVol = path: "${path}  *${opts}";
        volumes = builtins.concatStringsSep "\n" (map nfsVol paths);
      in
      {
        enable = true;
        exports = ''
          /export *(rw,fsid=0,no_subtree_check,insecure)
          ${volumes}
        '';
      };
    promtail = common.templates.promtail { inherit hostname; };
    prometheus.exporters = common.templates.prometheus_exporters { };
  } // common.services;

  system.stateVersion = "22.11";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
