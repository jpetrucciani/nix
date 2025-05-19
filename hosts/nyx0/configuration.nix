{ config, flake, machine-name, pkgs, ... }:
let
  hostname = "nyx0";
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
    enable = false;
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
      infinity.enable = false;
      koboldcpp.servers = {
        minicpm = {
          enable = false;
          port = 5001;
          model = modelPath "MiniCPM-V-2_6-Q8_0.gguf";
          mmproj = modelPath "mmproj-MiniCPM-V-2_6-f16.gguf";
          gpulayers = -1;
        };
      };
      llama-server.servers = {
        qwen3-4b = {
          enable = true;
          package = pkgs.llama-cpp-latest;
          port = 8013;
          model = modelPath "Qwen3-4B-UD-Q6_K_XL.gguf";
          ngl = 99;
          extraFlags = ''--ctx-size 32768 --seed 420 --prio 2 --temp 0.6 --min-p 0.0 --top-k 20 --top-p 0.95'';
        };
        bge-m3 = {
          enable = true;
          package = pkgs.llama-cpp-latest;
          ngl = 99;
          port = 9100;
          model = modelPath "bge-m3-FP16.gguf";
          extraFlags = "-c 65536 -np 8 -b 8192 -ub 8192 --pooling cls --embedding";
        };
        bge-m3-rerank = {
          enable = true;
          package = pkgs.llama-cpp-latest;
          ngl = 99;
          port = 9101;
          model = modelPath "bge-reranker-v2-m3-FP16.gguf";
          extraFlags = "-c 65536 -np 8 -b 8192 -ub 8192 -fa -lv 1 --reranking";
        };
      };
      prometheus.exporters.node.enable = true;
    };
}
