{ config, pkgs, ... }:
let
  hostname = "luna";
  common = import ../common.nix { inherit config pkgs; };
in
{
  imports = [
    "${common.home-manager.path}/nixos"
    "${common.mms}/nixos/modules/services/games/minecraft-servers"
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

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.kernel.sysctl = { } // common.sysctl_opts;
  boot.tmpOnTmpfs = true;

  environment.etc."nixpkgs-path".source = common.pinned.path;
  environment.variables = {
    NIX_HOST = hostname;
    NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
  };

  time.timeZone = common.timeZone;

  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  i18n.defaultLocale = common.defaultLocale;
  i18n.extraLocaleSettings = common.extraLocaleSettings;

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  users.users.jacobi = {
    isNormalUser = true;
    description = "jacobi";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      firefox
    ];
    openssh.authorizedKeys.keys = with common.pubkeys; [
      m1max
      nix-m1max
    ] ++ usual;
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [ ];

  networking.firewall.enable = false;
  services = {
    inherit (common._services) blocky;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    xserver = {
      enable = true;
      displayManager.lightdm.enable = true;
      desktopManager.xfce.enable = true;
      videoDrivers = [ "amdgpu" ];
      layout = "us";
      xkbVariant = "";
    };
    modded-minecraft-servers = with common.minecraft; {
      eula = true;
      instances = {
        rlcraft = {
          inherit (conf) jvmOpts;
          enable = true;
          rsyncSSHKeys = [ common.pubkeys.pluto ];
          jvmPackage = conf.jre8;
          jvmInitialAllocation = "8G";
          jvmMaxAllocation = "10G";
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
          enable = true;
          rsyncSSHKeys = [ common.pubkeys.pluto ];
          jvmPackage = conf.jre17;
          jvmInitialAllocation = "8G";
          jvmMaxAllocation = "10G";
          serverConfig =
            conf.defaults
              // {
              server-port = 25570;
              rcon-port = 25571;
              motd = "jacobi's vaulthunter server";
            };
        };
      };
    };
    n8n = {
      enable = true;
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
  } // common.services;

  systemd.services.n8n.serviceConfig.EnvironmentFile = "/etc/default/n8n";

  virtualisation.docker.enable = true;
  system.stateVersion = "22.11";
  security.sudo = common.security.sudo;
  programs.command-not-found.enable = false;
}
