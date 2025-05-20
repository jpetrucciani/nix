{ config, flake, machine-name, pkgs, ... }:
let
  inherit (import ../constants.nix) subs;
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
      pluto
    ];
  };

  services =
    let
      modelPath = name: "/opt/box/models/${name}";
    in
    {
      # infinity.enable = true;
      llama-server.servers = {
        qwen3-4b = {
          enable = true;
          package = pkgs.llama-cpp-latest;
          port = 8013;
          model = modelPath "Qwen3-4B-UD-Q6_K_XL.gguf";
          ngl = 99;
          extraFlags = ''--ctx-size 32768 --seed 420 --prio 2 --temp 0.6 --min-p 0.0 --top-k 20 --top-p 0.95'';
        };
      };
      # prometheus.exporters.node.enable = true;
    };

  system.stateVersion = 4;
  nix = {
    extraOptions = ''
      extra-experimental-features = nix-command flakes
      extra-substituters = ${subs.medable.url} ${subs.jacobi.url} ${subs.g7c.url}
      extra-trusted-public-keys = ${subs.medable.key} ${subs.jacobi.key} ${subs.g7c.key}
      keep-outputs = true
      builders = ssh://jacobi@neptune x86_64-linux - 8 - big-parallel;
      builders-use-substitutes = true
    '';
    nixPath = [
      "darwin=${common.nix-darwin}"
      "darwin-config=${configPath}"
    ];
    settings = {
      trusted-users = [ "root" "jacobi" ];
    };
  };
}
