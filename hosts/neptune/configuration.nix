{ config, pkgs, ... }:
let
  hostname = "neptune";
  common = import ../common.nix { inherit config pkgs; };
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
      grub.device = "/dev/nvme0n1";
    };
    kernel.sysctl = {
      "fs.inotify.max_user_watches" = "1048576";
    };
    tmpOnTmpfs = true;
  };

  environment.variables = {
    NIX_HOST = hostname;
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
  };

  time.timeZone = common.timeZone;

  networking.hostName = hostname;
  networking.useDHCP = false;
  networking.interfaces.enp9s0.useDHCP = true;
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedTCPPorts = with common.ports; [ ] ++ usual;
    allowedUDPPorts = [ ];
  };

  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";
  users.users.jacobi = {
    inherit (common) extraGroups;
    isNormalUser = true;
    passwordFile = "/etc/passwordFile-jacobi";

    openssh.authorizedKeys.keys = with common.pubkeys; [
      m1max
    ] ++ usual;
  };

  environment.systemPackages = [ pkgs.k3s ];

  services = {
    k3s = {
      enable = true;
      role = "server";
    };
    caddy = {
      enable = true;
      package = pkgs.xcaddy;
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
        "cobi.dev" = {
          extraConfig = ''
            route /static/* {
              s3proxy {
                bucket "jacobi-static"
                force_path_style
              }
            }
            route / {
              redir https://github.com/jpetrucciani/
            }
            route /nixup {
              redir https://raw.githubusercontent.com/jpetrucciani/nix/main/scripts/nixup.sh
            }
            route /nixos-up {
              redir https://github.com/samuela/nixos-up/archive/main.tar.gz
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
    defaults.email = common.emails.personal;
  };
  programs.command-not-found.enable = false;
}
