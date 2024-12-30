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
      infinity = {
        enable = true;
        models = [
          "jinaai/jina-embeddings-v3"
          "nomic-ai/nomic-embed-text-v1.5"
        ];
      };
      llama-server.servers = {
        llama3 = {
          enable = true;
          port = 8012;
          model = modelPath "Llama-3.2-3B-Instruct-Q8_0.gguf";
          ngl = 41;
        };
        llama3-1b = {
          enable = true;
          port = 8013;
          model = modelPath "Llama-3.2-1B-Instruct-Q8_0.gguf";
          ngl = 41;
        };
      };
    };
}
