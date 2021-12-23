{ config, pkgs, ... }:
let
  common = import ../common.nix { inherit config pkgs; };
  configPath = "/Users/jacobi/.config/nixpkgs/hosts/m1max/configuration.nix";
  username = "jacobi";
in
{
  imports = [
    "${common.home-manager}/nix-darwin"
  ];

  home-manager.users.jacobi = { pkgs, ... }: common.jacobi;
  _module.args.pkgs = common.pinned;

  time.timeZone = common.timeZone;
  environment.variables = {
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
  system.stateVersion = 4;
  nix = common.nix // {
    useDaemon = true;
    nixPath = [ "darwin=${common.nix-darwin}" "darwin-config=${configPath}" ];
  };

  programs.bash.enable = true;

  homebrew = {
    enable = true;
    autoUpdate = true;
    cleanup = "zap";

    # fix brew on m1. see: https://github.com/LnL7/nix-darwin/pull/304/files
    brewPrefix = "/opt/homebrew/bin";

    taps = [
      "homebrew/cask"
      "homebrew/cask-drivers"
      "homebrew/cask-fonts"
      "homebrew/cask-versions"
      "homebrew/core"
      "homebrew/services"
    ];

    brews = [
      "readline"
    ];

    casks = [
      # tools
      "insomnia"
      "bitwarden"
      "1password"
      "dropbox"
      "slack"
      "discord"

      # utils
      "alfred"
      "rectangle"
      "karabiner-elements"
    ];

    masApps = {
      # Tailscale = 1470499037; # doesn't work on m1?
    };

    extraConfig = "";
  };
}
