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

  system.stateVersion = 4;
  nix = {
    extraOptions = ''
      extra-experimental-features = nix-command flakes
      extra-substituters = https://medable.cachix.org https://jacobi.cachix.org
      extra-trusted-public-keys = medable.cachix.org-1:FhcOls9dE6to37lWBsKaTImxFxNIxW4NoG1cr/UOLLo= jacobi.cachix.org-1:JJghCz+ZD2hc9BHO94myjCzf4wS3DeBLKHOz3jCukMU=
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
