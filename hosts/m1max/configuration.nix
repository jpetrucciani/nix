{ config, pkgs, ... }:
let
  hostname = "m1max";
  common = import ../common.nix { inherit config pkgs; };
  configPath = "/Users/jacobi/.config/nixpkgs/hosts/${hostname}/configuration.nix";
  username = "jacobi";
in
{
  imports = [
    "${common.home-manager.path}/nix-darwin"
    "${common.nix-darwin}/modules/security/pam.nix"
  ];

  home-manager.users.jacobi = common.jacobi;

  time.timeZone = common.timeZone;
  environment.variables = {
    NIX_HOST = hostname;
    NIXDARWIN_CONFIG = configPath;
  };
  environment.darwinConfig = configPath;

  users.users.jacobi = {
    name = username;
    home = "/Users/${username}";
  };

  system = {
    defaults = {
      NSGlobalDomain = {
        AppleKeyboardUIMode = 3;
        ApplePressAndHoldEnabled = false;
        InitialKeyRepeat = 10;
        KeyRepeat = 1;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        _HIHideMenuBar = false;
      };

      screencapture = { location = "/tmp"; };
      dock = {
        autohide = true;
        mru-spaces = false;
        orientation = "left";
        showhidden = true;
      };

      finder = {
        AppleShowAllExtensions = true;
        QuitMenuItem = true;
        FXEnableExtensionChangeWarning = false;
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

  };

  security.pam.enableSudoTouchIdAuth = true;
  system.stateVersion = 4;
  nix = common.nix // {
    useDaemon = true;
    nixPath = [
      "darwin=${common.nix-darwin}"
      "darwin-config=${configPath}"
    ];
  };

  programs.bash.enable = true;

  homebrew = {
    inherit (common.mac) taps brews;
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
    # fix brew on m1. see: https://github.com/LnL7/nix-darwin/pull/304/files
    brewPrefix = "/opt/homebrew/bin";
    casks = common.mac.casks.all_work;
    masApps = common.mac.apps;
    extraConfig = "";
  };
}
