{ config, flake, machine-name, pkgs, ... }:
let
  hostname = "m1max";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
  configPath = "/Users/jacobi/cfg/hosts/${hostname}/configuration.nix";
  username = "jacobi";
in
{
  imports = [
    "${common.home-manager}/nix-darwin"
    "${common.nix-darwin}/modules/security/pam.nix"
  ];

  conf.work.enable = true;

  home-manager.users.jacobi = common.jacobi;
  documentation.enable = false;
  security.pam.enableSudoTouchIdAuth = true;

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

  services =
    let
      modelPath = name: "/opt/box/models/${name}";
    in
    {
      infinity.enable = true;
      llama-server.servers = {
        r1-14b = {
          enable = true;
          port = 8012;
          model = modelPath "DeepSeek-R1-Distill-Qwen-14B-Q8_0.gguf";
          extraFlags = ''-md DeepSeek-R1-Distill-Qwen-1.5B-Q8_0.gguf -ngld 99'';
          ngl = 99;
        };
        r1-1-5b = {
          enable = true;
          port = 8013;
          model = modelPath "DeepSeek-R1-Distill-Qwen-1.5B-Q8_0.gguf";
          ngl = 99;
        };
      };
      prometheus.exporters.node.enable = true;
    };

  system.stateVersion = 4;
  nix = {
    extraOptions = ''
      extra-experimental-features = nix-command flakes
      extra-substituters = https://medable-nix.s3.us-west-1.amazonaws.com https://jacobi.cachix.org
      extra-trusted-public-keys = medable-nix.s3.us-west-1.amazonaws.com:dtdREarYUM5iVkNgmcJyL1aYfzVL2Pgfq4a5godxCVk= jacobi.cachix.org-1:JJghCz+ZD2hc9BHO94myjCzf4wS3DeBLKHOz3jCukMU=
      keep-outputs = true
      builders = ssh://jacobi@neptune x86_64-linux - 8 - big-parallel;
      builders-use-substitutes = true
    '';
    useDaemon = true;
    nixPath = [
      "darwin=${common.nix-darwin}"
      "darwin-config=${configPath}"
    ];
    settings = {
      trusted-users = [ "root" "jacobi" ];
    };
  };
}
