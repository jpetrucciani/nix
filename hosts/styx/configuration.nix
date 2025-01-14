{ config, flake, machine-name, pkgs, ... }:
let
  hostname = "styx";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
  configPath = "/Users/jacobi/cfg/hosts/${hostname}/configuration.nix";
  username = "jacobi";
in
{
  imports = [
    "${common.home-manager}/nix-darwin"
  ];

  home-manager.users.jacobi = common.jacobi;
  documentation.enable = false;

  time.timeZone = common.timeZone;
  environment.variables = {
    NIX_HOST = hostname;
    NIXDARWIN_CONFIG = configPath;
  };
  environment.darwinConfig = configPath;

  users.users.jacobi = {
    name = username;
    home = "/Users/${username}";
    openssh.authorizedKeys.keys = with common.pubkeys; [
      galaxyboss
      milkyway
      pluto
    ];
  };

  system.stateVersion = 4;
  nix = common.nix // {
    useDaemon = true;
    nixPath = [
      "darwin=${common.nix-darwin}"
      "darwin-config=${configPath}"
    ];
    settings = {
      trusted-users = [ "root" "jacobi" ];
    };
  };

  services =
    let
      modelPath = name: "/opt/box/models/${name}";
    in
    {
      infinity.enable = true;
      koboldcpp.servers = {
        minicpm = {
          enable = true;
          port = 5001;
          model = modelPath "MiniCPM-V-2_6-Q8_0.gguf";
          mmproj = modelPath "mmproj-MiniCPM-V-2_6-f16.gguf";
          gpulayers = -1;
        };
      };
      llama-server.servers = {
        llama3 = {
          enable = true;
          port = 8012;
          model = modelPath "Llama-3.2-3B-Instruct-Q8_0.gguf";
          # ngl = 41;
        };
        nuextract = {
          enable = true;
          port = 8013;
          model = modelPath "NuExtract-v1.5-Q6_K_L.gguf";
        };
        qwen-25-7b = {
          enable = true;
          port = 8014;
          model = modelPath "Qwen2.5-7B-Instruct-Q8_0.gguf";
          ngl = 81;
        };
      };
    };
}
