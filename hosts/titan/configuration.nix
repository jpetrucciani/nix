{ config, flake, machine-name, pkgs, ... }:
let
  inherit (flake.inputs) nixos-hardware;
  hostname = "titan";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    ./hardware-configuration.nix
  ] ++ (with nixos-hardware.nixosModules; [
    common-cpu-amd
    common-cpu-amd-pstate
    common-pc
    common-pc-ssd
  ]);

  inherit (common) zramSwap swapDevices;

  nix = common.nix-cuda // {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/jacobi/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  home-manager.users.jacobi = common.jacobi;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernel.sysctl = { } // common.sysctl_opts;
    tmp.useTmpfs = true;
  };

  environment = {
    variables = {
      NIX_HOST = hostname;
      NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
    };
    systemPackages = with pkgs; [
      cudaPackages.cudatoolkit
      cudaPackages.cudnn
      nvidia-docker
      nvtopPackages.nvidia
      linuxPackages.nvidia_x11
    ];
  };

  time.timeZone = common.timeZone;

  networking = {
    hostName = hostname;
    useDHCP = true;
    interfaces.enp5s0.useDHCP = true;
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
        openssh.authorizedKeys.keys = with common.pubkeys; usual;
      };
    };
  };

  services = {
    xserver.videoDrivers = [ "nvidia" ];
    promtail = common.templates.promtail { inherit hostname; };
    prometheus.exporters = common.templates.prometheus_exporters { };
    qdrant = {
      enable = true;
      settings = {
        service = {
          host = "0.0.0.0";
        };
      };
    };
    caddy =
      let
        reverse_proxy = location: {
          extraConfig = ''
            # import TAILSCALE
            reverse_proxy /* {
              to ${location}
            }
          '';
        };
        m1max = "192.168.1.101";
      in
      {
        enable = true;
        package = pkgs.zaddy;
        email = common.emails.personal;
        extraConfig = ''
          (TAILSCALE) {
            @tailscale not remote_ip 127.0.0.1 100.64.0.0/10
            respond @tailscale "Kek" 403
          }
        '';
        virtualHosts = {
          "http://zephyr.llm.cobi.dev:80" = reverse_proxy "${m1max}:8100";
          "http://starling.llm.cobi.dev:80" = reverse_proxy "${m1max}:8101";
          "http://airoboros.llm.cobi.dev:80" = reverse_proxy "${m1max}:8102";
          "http://hermes.llm.cobi.dev:80" = reverse_proxy ''
            ${m1max}:6910 ${m1max}:6911
            lb_policy round_robin
          '';
          "http://llava.llm.cobi.dev:80" = reverse_proxy "${m1max}:8080";
          "http://v.llm.cobi.dev:80" = reverse_proxy "localhost:8000";
        };
      };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      extraPlugins = with pkgs.postgresql16Packages; [ pgvector ];
      enableTCPIP = true;
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
        host all all 127.0.0.1/32 trust
        host all all ::1/128 trust
        host all all 100.64.0.0/10 trust
      '';
    };
  } // common.services;

  system.stateVersion = "23.11";
  security.sudo = common.security.sudo;
  programs = {
    command-not-found.enable = false;
    nix-ld.enable = true;
  };

  # nvidia setup?
  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
  };
  hardware = {
    nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
  };
}
