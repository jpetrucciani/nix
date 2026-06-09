{ config, flake, machine-name, pkgs, ... }:
let
  hostname = "cy1-nix-01";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./hardware-configuration.nix
    ../modules/conf/blackedge.nix
  ];

  inherit (common) zramSwap swapDevices;

  nix = common.nix-be // {
    package = pkgs._nix;
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/jacobi/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  home-manager.users.jacobi = common.jacobi;

  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      systemd-boot.enable = true;
    };
    kernel.sysctl = { } // common.sysctl_opts;
    tmp.useTmpfs = true;
    supportedFilesystems = [ "nfs" ];
  };

  environment = {
    variables = {
      NIX_HOST = hostname;
      NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
    };
    etc = {
      "nixpkgs-path".source = common.pkgs.path;
    };
    systemPackages = with pkgs; [
      amazon-ecr-credential-helper
      cifs-utils
      nfs-utils
    ];
  };

  time.timeZone = common.tz.work;

  networking = {
    hostName = hostname;
    nameservers = [ "10.31.65.200" "1.1.1.1" ];
    search = [ "blackedge.local" ];
    useDHCP = false;
    interfaces.ens2f0np0.useDHCP = true;
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
        openssh.authorizedKeys.keys = with common.pubkeys; [ edge ] ++ usual;
      };
    };
  };

  conf.blackedge = {
    enable = true;
    allowedGroups = [ "systems" ];
  };

  services = {
    logind.settings.Login = {
      RuntimeDirectorySize = "24G";
    };
    resolved = {
      enable = true;
      settings.Resolve.FallbackDNS = [ "10.31.65.200" "10.31.155.10" "1.1.1.1" ];
    };
    rpcbind.enable = true;
    _3proxy = {
      enable = true;
      services = [{
        type = "socks";
        auth = [ "none" ];
      }];
    };
    titanite = {
      enable = true;
      settings = {
        listen_udp = "0.0.0.0:53";
        listen_tcp = "0.0.0.0:53";
        upstream_timeout_ms = 2000;
        upstreams = [
          {
            address = "1.1.1.1:53";
            priority = 0;
          }
          {
            address = "1.0.0.1:53";
            priority = 10;
          }
        ];
        forward_zones = [
          {
            name = "blackedge.local";
            upstream = "10.31.155.10:53";
          }
        ];
        observe = {
          metrics.listen = "127.0.0.1:9191";
          logging.structured = true;
          passive_dns = {
            enabled = false;
            path = "/var/log/titanite/passive.jsonl";
            deduplicate_window = "1h";
            retention = "30d";
            anonymize_client_ip = true;
          };
        };
        zones = [
          {
            name = "x";
            records =
              let
                record = name: value: { inherit name value; type = "A"; ttl = 300; };
                records = {
                  "meme.x" = "100.127.34.123";
                };
              in
              [ ] ++ (pkgs.lib.mapAttrsToList record records);
          }
        ];
        plugins = [
          {
            name = "toys";
            type = "toys";
            zone = "toy";
            enabled_toys = [ "ip" "time" "cidr" "uuid" "rand" "epoch" "hash" "health" "stats" "version" ];
            priority = -1;
            fail_open = true;
            timeout = "50ms";
          }
        ];
      };
    };
  } // common.services;

  fileSystems."/mnt/win" = {
    device = "//aur-jpetrucciani-01.blackedge.local/c$/mnt";
    fsType = "cifs";
    options =
      let
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      in
      [ "${automount_opts},credentials=/etc/default/smb-secrets,uid=1000,gid=100" ];
  };

  virtualisation.docker.enable = true;
  system.stateVersion = "26.05";
  security.sudo = common.security.sudo;
  programs = {
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        libcap
        xz
        openssl
        zlib
      ];
    };
  };
  security.pam.loginLimits = [
    { domain = "*"; item = "nofile"; type = "-"; value = "131072"; }
  ];
}
