{ config, flake, machine-name, pkgs, lib, ... }:
let
  inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib.trivial) flip;

  mapAttrValues = f: builtins.mapAttrs (_: f);
  forAttrValues = flip mapAttrValues;

  hostname = "charon";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
  configPath = "/Users/jacobi/cfg/hosts/${hostname}/configuration.nix";
  username = "jacobi";

  runner-defaults = {
    url = "https://github.com/jpetrucciani/nix";
    extraLabels = [ "nix" "m1" ];
    extraPackages = [ ];
  };
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
  };

  services.github-runners = mapAttrs' (n: nameValuePair "runner-${n}") {
    jpetrucciani-nix = runner-defaults // {
      extraPackages = with pkgs; [ gh cachix ];
      tokenFile = "/etc/default/gh.token";
    };
  };

  launchd.daemons = forAttrValues config.services.github-runners (cfg: {
    # daemon path fixes copied from the nixos module
    path = with pkgs;[
      bash
      coreutils
      git
      gnutar
      gzip
    ] ++ [
      (
        # allow x64 runners
        if cfg.package != pkgsx86_64Darwin.github-runner
        then config.nix.package
        else pkgsx86_64Darwin.nix
      )
    ] ++ cfg.extraPackages;
  });
}
