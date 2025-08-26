{ config, flake, machine-name, pkgs, lib, ... }:
let
  hostname = "edge";
  ts_ip = "100.69.215.126";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./hardware-configuration.nix
    ../modules/conf/blackedge.nix
    ../modules/conf/ssh-remote-bind.nix
    ../modules/servers/goto.nix
  ];

  inherit (common) zramSwap swapDevices;

  nix = common.nix-be // {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/jacobi/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  home-manager.users.jacobi = common.jacobi;

  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda";
        useOSProber = true;
      };
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
      "rancher/k3s/kubelet.config".source = pkgs.writeTextFile {
        name = "kubelet.config";
        text = ''
          apiVersion: kubelet.config.k8s.io/v1beta1
          kind: KubeletConfiguration
          maxPods: 250
        '';
      };
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
    interfaces.eth0.useDHCP = true;
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
        openssh.authorizedKeys.keys = with common.pubkeys; [ edgewin hub2 ] ++ usual;
      };
    };
  };

  conf.blackedge.enable = true;

  services = {
    logind.settings.Login = {
      RuntimeDirectorySize = "24G";
    };
    resolved = {
      enable = true;
      fallbackDns = [ "10.31.65.200" "10.31.155.10" "1.1.1.1" ];
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
      enableTCPIP = true;
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
        host all all 127.0.0.1/32 trust
        host all all ::1/128 trust
        host all all 100.64.0.0/10 trust
      '';
    };
    k3s =
      let
        oidc_flags = builtins.concatStringsSep " " [
          "--kube-apiserver-arg=oidc-issuer-url=https://accounts.google.com"
          "--kube-apiserver-arg=oidc-client-id=356820992289-89b30uojlrkqkm79g6hb0216d7j9ru9s.apps.googleusercontent.com"
          "--kube-apiserver-arg=oidc-username-claim=email"
          "--kube-apiserver-arg=oidc-groups-claim=groups"
        ];
      in
      {
        enable = true;
        role = "server";
        extraFlags = "--disable traefik --tls-san '${ts_ip}' ${oidc_flags} --kubelet-arg=config=/etc/rancher/k3s/kubelet.config";
      };
    caddy =
      let
        internal_proxy = { port ? 10000, host ? "127.0.0.1" }: {
          extraConfig = ''
            tls /opt/crt/bec.crt /opt/crt/bec.key
            reverse_proxy /* {
              to ${host}:${toString port}
            }
          '';
        };
      in
      {
        enable = true;
        package = pkgs.zaddy;
        email = common.emails.personal;
        extraConfig = ''
          (SECURITY) {
            encode zstd gzip
            header {
              -Server
              Strict-Transport-Security "max-age=31536000; include-subdomains;"
              X-XSS-Protection "1; mode=block"
              X-Frame-Options "DENY"
              X-Content-Type-Options nosniff
              Referrer-Policy  no-referrer-when-downgrade
              X-Robots-Tag "none"
            }
          }
        '';
        virtualHosts = {
          "http://go:80" = {
            extraConfig = ''
              reverse_proxy /* {
                to localhost:4200
              }
            '';
          };
          "http://grid:80" = {
            extraConfig = ''
              route /* {
                s3proxy {
                  bucket "blackedge-ops"
                  region "us-east-2"
                  root /apps/griddy/v/0.0.4
                }
              }
            '';
          };
          "http://griddy-staging:80" = {
            extraConfig = ''
              route /* {
                s3proxy {
                  bucket "blackedge-ops"
                  region "us-east-2"
                  root /apps/griddy/v/staging
                }
              }
            '';
          };
          "edge.blackedge.capital" = internal_proxy { };
          "ds.blackedge.capital" = let f = "10.31.41.212"; in {
            extraConfig = ''
              tls /opt/crt/bec.crt /opt/crt/bec.key
              reverse_proxy /* {
                to ${f}:5000 ${f}:5001
                lb_policy round_robin
              }
            '';
          };
        };
      };
    goto.enable = true;
    rpcbind.enable = true;
    _3proxy = {
      enable = true;
      services = [{
        type = "socks";
        auth = [ "none" ];
      }];
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
  virtualisation.vmware.guest.enable = true;
  system.stateVersion = "23.11";
  security.sudo = common.security.sudo;
  programs = {
    command-not-found.enable = false;
    nix-ld.enable = true;
  };
  security.pam.loginLimits = [
    { domain = "*"; item = "nofile"; type = "-"; value = "131072"; }
  ];
}
