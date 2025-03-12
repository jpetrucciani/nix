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
        gemma3 = {
          enable = true;
          port = 8012;
          model = modelPath "gemma-3-27b-it-Q5_K_M.gguf";
          extraFlags = ''--ctx-size 16384 --seed 3407 --prio 2 --temp 1.0 --repeat-penalty 1.0 --min-p 0.01 --top-k 64 --top-p 0.95'';
          ngl = 99;
        };
        r1-1-5b = {
          enable = true;
          port = 8013;
          model = modelPath "DeepSeek-R1-Distill-Qwen-1.5B-Q8_0.gguf";
          ngl = 99;
        };
        deepscaler-1-5b = {
          enable = true;
          port = 8014;
          model = modelPath "agentica-org_DeepScaleR-1.5B-Preview-Q8_0.gguf";
          ngl = 99;
        };
      };
      mlx-vlm-api.servers.qwen-2-5-vl-7b.enable = true;
      prometheus.exporters.node.enable = true;
    };
}
