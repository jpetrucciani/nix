{ config, pkgs, ... }:
let
  common = import ../common.nix { inherit config pkgs; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./hardware-configuration.nix
  ];

  inherit (common) nix zramSwap;

  home-manager.users.jacobi = { pkgs, ... }: common.jacobi;
  nixpkgs.pkgs = common.pinned;

  boot = {
    loader = {
      grub.enable = true;
      grub.version = 2;
      grub.device = "/dev/nvme0n1";
    };
    kernel.sysctl = {
      "fs.inotify.max_user_watches" = "1048576";
    };
    tmpOnTmpfs = true;
  };

  environment.variables = {
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/neptune/configuration.nix";
  };

  time.timeZone = common.timeZone;

  networking.hostName = "neptune";
  networking.useDHCP = false;
  networking.interfaces.enp9s0.useDHCP = true;
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedTCPPorts = [ ] ++ common.ports.common;
    allowedUDPPorts = [ ];
  };

  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";
  users.users.jacobi = {
    isNormalUser = true;
    extraGroups = common.extraGroups;
    passwordFile = "/etc/passwordFile-jacobi";

    openssh.authorizedKeys.keys = with common.pubkeys; [
      m1max
    ] ++ common.pubkeys.common;
  };

  environment.systemPackages = [ pkgs.k3s ];
  services = {
    k3s = {
      enable = true;
      role = "server";
    };
    caddy = {
      enable = true;
      email = common.emails.personal;
      virtualHosts = {
        "home.cobi.dev" = {
          extraConfig = ''
            reverse_proxy /* {
              to home:${toString common.ports.home-assistant}
            }
          '';
        };
        "netdata.cobi.dev" = {
          extraConfig = ''
            reverse_proxy /* {
              to localhost:${toString common.ports.netdata}
            }
          '';
        };
        "flix.cobi.dev" = {
          extraConfig = ''
            reverse_proxy /* {
              to jupiter:${toString common.ports.plex}
            }
          '';
        };
      };
    };
  } // common.services;
  virtualisation.docker.enable = true;

  system.stateVersion = "22.05";
  security.sudo = common.security.sudo;
  security.acme = {
    acceptTerms = true;
    email = common.emails.personal;
  };
  programs.command-not-found.enable = false;
}
