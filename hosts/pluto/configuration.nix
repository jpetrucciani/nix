{ config, flake, machine-name, pkgs, ... }:
let
  hostname = "pluto";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
  configPath = "/Users/jacobi/cfg/hosts/${hostname}/configuration.nix";
  username = "jacobi";
in
{
  imports = [
    "${common.home-manager}/nix-darwin"
    "${common.nix-darwin}/modules/security/pam.nix"
  ];

  home-manager.users.jacobi = common.jacobi;
  documentation.enable = false;
  security.pam.services.sudo_local.touchIdAuth = true;

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
      voyager
    ];
  };

  system.stateVersion = 4;
  nix = common.nix // {
    nixPath = [
      "darwin=${common.nix-darwin}"
      "darwin-config=${configPath}"
    ];
  };

  # services.llama-server.servers.llama3 = {
  #   enable = false;
  #   port = 8012;
  #   model = "/opt/box/models/Llama-3.2-3B-Instruct-Q8_0.gguf";
  #   ngl = 41;
  # };
  services =
    {
      # infinity.enable = true;
      koboldcpp.servers = {
        # minicpm = {
        #   enable = true;
        #   port = 5001;
        #   model = modelPath "MiniCPM-V-2_6-Q8_0.gguf";
        #   mmproj = modelPath "mmproj-MiniCPM-V-2_6-f16.gguf";
        #   gpulayers = -1;
        # };
      };
      llama-server.servers = {
        # gemma3 = {
        #   enable = true;
        #   package = pkgs.llama-cpp-latest;
        #   port = 8012;
        #   model = modelPath "gemma-3-27b-it-Q5_K_M.gguf";
        #   extraFlags = ''--ctx-size 16384 --seed 3407 --prio 2 --temp 1.0 --repeat-penalty 1.0 --min-p 0.01 --top-k 64 --top-p 0.95'';
        #   ngl = 99;
        # };
        # qwen-25-coder-7b = {
        #   enable = true;
        #   package = pkgs.llama-cpp-latest;
        #   port = 8014;
        #   model = modelPath "Qwen2.5.1-Coder-7B-Instruct-Q6_K_L.gguf";
        #   ngl = 81;
        # };
      };
    };
}
