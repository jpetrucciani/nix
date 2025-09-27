{ lib, flake, machine-name, pkgs, config, modulesPath, ... }:
let
  hostname = "milkyway";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
  cuda = pkgs.cudaPackages.cudatoolkit;
  CUDA_PATH = cuda.outPath;
  CUDA_LDPATH = "${
      lib.concatStringsSep ":" [
        pkgs.hax.nvidiaLdPath
        "/run/opengl-drivers/lib"
        # "/run/opengl-drivers-32/lib"
        "${cuda}/lib"
      ]
    }:${
      lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib cuda.lib ]
    }";
in
{
  imports = [
    "${common.home-manager}/nixos"
    "${modulesPath}/profiles/minimal.nix"
    flake.inputs.nixos-wsl.nixosModules.wsl
  ];

  boot.tmp.useTmpfs = true;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  environment = {
    etc."nixpkgs-path".source = common.pkgs.path;
    # cuda stuff?
    systemPackages = with pkgs; [
      nvidia-docker
    ];
    variables = {
      NIX_HOST = hostname;
      NIXOS_CONFIG = "/home/jacobi/cfg/hosts/${hostname}/configuration.nix";
      _CUDA_PATH = CUDA_PATH;
      _CUDA_LDPATH = CUDA_LDPATH;
      XLA_FLAGS = "--xla_gpu_cuda_data_dir=${CUDA_PATH}";
    };
  };
  # fonts.packages = with pkgs; [
  #   nerdfonts
  # ];
  home-manager.users.jacobi = common.jacobi;
  wsl = {
    enable = true;
    defaultUser = "jacobi";
    startMenuLaunchers = true;
    wslConf.automount.root = "/mnt";

    wslConf.network.generateHosts = false;
    # Enable native Docker support
    # docker-native.enable = true;
    interop.register = true;
  };

  networking = {
    extraHosts = ''
      100.88.176.6 llm.cobi.dev
    '';
    hostName = hostname;
  };
  nix = common.nix-cuda // {
    package = pkgs._nix;
    nixPath = [
      "nixpkgs=/etc/nixpkgs-path"
      "nixos-config=/home/jacobi/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
  programs = {
    command-not-found.enable = false;
    nix-ld.enable = true;
  };

  security.sudo = common.security.sudo;
  system.stateVersion = "23.11";
  time.timeZone = common.timeZone;

  users.users.jacobi = {
    isNormalUser = true;
    description = "jacobi";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    openssh.authorizedKeys.keys = with common.pubkeys; [
      m1max
      nix-m1max
    ] ++ usual;
  };

  services = {
    xserver.videoDrivers = [ "nvidia" ];
  } // common.services;

  virtualisation.docker = {
    enable = true;
    daemon.settings.features.cdi = true;
    daemon.settings.cdi-spec-dirs = [ "/etc/cdi" ];
    # https://github.com/nix-community/NixOS-WSL/issues/578
    ### sudo mkdir -p /etc/cdi
    ### LD_LIBRARY_PATH=/usr/lib/wsl/lib nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia-container-toolkit = {
      enable = true;
      mount-nvidia-executables = false;
    };
    nvidia = {
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  fileSystems."/mnt/jupiter" = {
    device = "100.84.224.73:/volume1/network";
    fsType = "nfs";
    options = [
      "nfsvers=4.1"
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };
}
