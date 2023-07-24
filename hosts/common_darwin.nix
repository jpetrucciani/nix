{ lib, config, ... }:
let
  inherit (lib.lists) subtractLists;
  inherit (lib) mkEnableOption;
  inherit (config.conf) work;
in
{
  options.conf.work = {
    enable = mkEnableOption "work";
  };
  config = {
    system = {
      defaults = {
        CustomSystemPreferences = {
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
          "com.apple.finder" = {
            ShowExternalHardDrivesOnDesktop = true;
            ShowHardDrivesOnDesktop = true;
            ShowMountedServersOnDesktop = true;
            ShowRemovableMediaOnDesktop = true;
            _FXSortFoldersFirst = true;
            # When performing a search, search the current folder by default
            FXDefaultSearchScope = "SCcf";
          };
          "com.apple.desktopservices" = {
            # Avoid creating .DS_Store files on network or USB volumes
            DSDontWriteNetworkStores = true;
            DSDontWriteUSBStores = true;
          };
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

    programs.bash.enable = true;

    homebrew =
      let
        casks = rec {
          fonts = [
            "font-caskaydia-cove-nerd-font"
            "font-fira-code-nerd-font"
            "font-hasklug-nerd-font"
          ];
          fun = [
            "spotify"
            "steam"
          ];
          work = [
            "1password"
            "dropbox"
            "robo-3t"
            "slack"
            "xca"
          ];
          comms = [
            "discord"
          ];
          util = [
            "alfred"
            "docker"
            "insomnia"
            "karabiner-elements"
            "keybase"
            "macfuse"
            "notion"
            "parsec"
            "qlvideo"
            "raycast"
            "rectangle"
            "utm"
          ];
          all = fonts ++ fun ++ work ++ comms ++ util;
          all_personal = subtractLists work all;
          all_work = subtractLists fun all;
        };
      in
      {
        enable = true;
        taps = [
          "homebrew/cask"
          "homebrew/cask-drivers"
          "homebrew/cask-fonts"
          "homebrew/cask-versions"
          "homebrew/core"
          "homebrew/services"
        ];
        brews = [
          "openconnect"
          "readline"
          "sshfs"
          "qemu"
        ];
        onActivation = {
          autoUpdate = true;
          cleanup = "zap";
          upgrade = true;
        };
        casks = if work.enable then casks.all_work else casks.all_personal;
        masApps = {
          Wireguard = 1451685025;
          Poolside = 1514817810;
        };
        extraConfig = "";
      };
  };
}
