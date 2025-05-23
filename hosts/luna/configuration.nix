{ config, flake, machine-name, pkgs, ... }:
let
  hostname = "luna";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    "${common.mms}/nixos/modules/services/games/minecraft-servers"
    ./hardware-configuration.nix
    ../modules/games/palworld.nix
    ../modules/games/stationeers.nix
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

  boot = {
    initrd.systemd.network.wait-online.enable = false;
    kernel.sysctl = { } // common.sysctl_opts;
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };
    tmp.useTmpfs = true;
  };
  systemd.network.wait-online.enable = false;

  environment = {
    etc."nixpkgs-path".source = common.pkgs.path;
    systemPackages = with pkgs; [
      # rocmPackages.rocm-smi
    ];
    variables = {
      NIX_HOST = hostname;
      NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
    };
  };

  time.timeZone = common.timeZone;

  networking = {
    hostName = hostname;
    # networkmanager.enable = true;
  };

  i18n.defaultLocale = common.defaultLocale;
  i18n.extraLocaleSettings = common.extraLocaleSettings;

  users.users.jacobi = {
    isNormalUser = true;
    description = "jacobi";
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = with common.pubkeys; [
      m1max
      nix-m1max
    ] ++ usual;
  };

  networking.firewall.enable = false;
  services = {
    inherit (common._services) blocky;
    pipewire = {
      enable = false;
      alsa.enable = false;
      alsa.support32Bit = false;
      pulse.enable = false;
    };
    xserver = {
      enable = false;
      # displayManager.lightdm.enable = true;
      # desktopManager.xfce.enable = true;
      # videoDrivers = [ "amdgpu" ];
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    stationeers = {
      enable = false;
      worldName = "memeworld";
    };
    palworld = {
      enable = true;
      worldSettings = {
        ExpRate = "3";
        ServerPassword = "$PALWORLD_SERVER_PASSWORD";
      };
    };
    modded-minecraft-servers = with common.minecraft; {
      eula = true;
      instances = {
        rlcraft = {
          inherit (conf) jvmOpts;
          enable = false;
          rsyncSSHKeys = [ common.pubkeys.pluto ];
          jvmPackage = conf.jre8;
          jvmInitialAllocation = "6G";
          jvmMaxAllocation = "8G";
          serverConfig =
            conf.defaults
              // {
              server-port = 25569;
              rcon-port = 25568;
              motd = "jacobi's rlcraft server";

              # rlcraft specific settings
              difficulty = 3;
              max-tick-time = -1;
              enable-command-block = true;
            };
        };
        vaulthunters = {
          inherit (conf) jvmOpts;
          enable = false;
          rsyncSSHKeys = [ common.pubkeys.pluto ];
          jvmPackage = conf.jre17;
          jvmInitialAllocation = "6G";
          jvmMaxAllocation = "8G";
          serverConfig =
            conf.defaults
              // {
              server-port = 25570;
              rcon-port = 25571;
              motd = "jacobi's vaulthunter server";
            };
        };
        vaulthunters-other = {
          inherit (conf) jvmOpts;
          enable = false;
          rsyncSSHKeys = [ common.pubkeys.pluto ];
          jvmPackage = conf.jre17;
          jvmInitialAllocation = "6G";
          jvmMaxAllocation = "8G";
          serverConfig =
            conf.defaults
              // {
              server-port = 25572;
              rcon-port = 25573;
              motd = "jacobi's other vaulthunter server";
            };
        };
      };
    };
    _3proxy = {
      enable = true;
      services = [{
        type = "socks";
        auth = [ "none" ];
      }];
    };
    step-ca =
      let
        base = "/var/lib/step-ca";
        certs = "${base}/certs";
        secrets = "${base}/secrets";
      in
      {
        enable = true;
        port = 443;
        address = "0.0.0.0";
        intermediatePasswordFile = "${secrets}/password";
        settings = {
          dnsNames = [ "cobi" ];
          root = "${certs}/root_ca.crt";
          crt = "${certs}/intermediate_ca.crt";
          key = "${secrets}/intermediate_ca_key";
          db = {
            type = "badger";
            dataSource = "${base}/db";
          };
          ssh = {
            hostKey = "${secrets}/ssh_host_ca_key";
            userKey = "${secrets}/ssh_user_ca_key";
          };
          logger = {
            format = "text";
          };
          claims = {
            minTLSCertDuration = "5m";
            maxTLSCertDuration = "90d";
            defaultTLSCertDuration = "24h";
          };
          authority = {
            provisioners = [
              {
                type = "ACME";
                name = "acme";
              }
              {
                type = "SSHPOP";
                name = "sshpop";
                claims = {
                  enableSSHCA = true;
                };
              }
            ];
          };
          tls = {
            cipherSuites = [
              "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
              "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
            ];
            minVersion = 1.2;
            maxVersion = 1.3;
            renegotiation = false;
          };
          templates = {
            ssh = {
              user = [
                {
                  name = "config.tpl";
                  type = "snippet";
                  template = "${base}/templates/ssh/config.tpl";
                  path = "~/.ssh/config";
                  comment = "#";
                }
                {
                  name = "step_includes.tpl";
                  type = "prepend-line";
                  template = "${base}/templates/ssh/step_includes.tpl";
                  path = ''''${STEPPATH}/ssh/includes'';
                  comment = "#";
                }
                {
                  name = "step_config.tpl";
                  type = "file";
                  template = "${base}/templates/ssh/step_config.tpl";
                  path = "ssh/config";
                  comment = "#";
                }
                {
                  name = "known_hosts.tpl";
                  type = "file";
                  template = "${base}/templates/ssh/known_hosts.tpl";
                  path = "ssh/known_hosts";
                  comment = "#";
                }
              ];
              host = [
                {
                  name = "sshd_config.tpl";
                  type = "snippet";
                  template = "${base}/templates/ssh/sshd_config.tpl";
                  path = "/etc/ssh/sshd_config";
                  comment = "#";
                  requires = [
                    "Certificate"
                    "Key"
                  ];
                }
                {
                  name = "ca.tpl";
                  type = "snippet";
                  template = "${base}/templates/ssh/ca.tpl";
                  path = "/etc/ssh/ca.pub";
                  comment = "#";
                }
              ];
            };
          };
        };
      };
    promtail = common.templates.promtail { inherit hostname; };
    prometheus.exporters = common.templates.prometheus_exporters { };
  } // common.services;

  virtualisation.docker.enable = true;
  virtualisation.oci-containers = {
    backend = "podman";
    containers.homeassistant = {
      volumes = [ "home-assistant:/config" ];
      environment.TZ = "US/Eastern";
      image = "ghcr.io/home-assistant/home-assistant:2024.1";
      extraOptions = [
        "--network=host"
      ];
    };
  };
  system.stateVersion = "23.11";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
