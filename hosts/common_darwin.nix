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
    # nix.linux-builder = {
    #   enable = true;
    #   package = pkgs.darwin.linux-builder-x86_64;
    # };
    system = {
      activationScripts.postUserActivation.text = ''
        # Following line should allow us to avoid a logout/login cycle
        /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
      '';
      defaults = {
        CustomSystemPreferences = {
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
        screencapture = { location = "/tmp"; type = "png"; };
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
    programs.bash = {
      enable = true;
      completion.enable = true;
    };
    homebrew =
      let
        casks = rec {
          fonts = [
            "font-caskaydia-cove-nerd-font"
            "font-fantasque-sans-mono-nerd-font"
            "font-fira-code-nerd-font"
            "font-hasklug-nerd-font"
            "font-victor-mono-nerd-font"
            "font-monaspace"
          ];
          fun = [
            "mgba"
            "spotify"
            "steam"
          ];
          work = [
            "1password"
            "robo-3t"
            "slack"
          ];
          comms = [
            "discord"
          ];
          util = [
            "docker"
            "ghostty"
            "insomnia"
            "karabiner-elements"
            "obsidian"
            "parsec"
            "qlvideo"
            "raycast"
            "rectangle"
            "utm"
            "vlc"
          ];
          all = fonts ++ fun ++ work ++ comms ++ util;
          all_personal = subtractLists work all;
          all_work = subtractLists fun all;
        };
      in
      {
        enable = true;
        taps = [
          "homebrew/services"
        ];
        brews = [
          "openconnect"
          "readline"
          "qemu"
          "unixodbc"
        ];
        onActivation = {
          autoUpdate = true;
          cleanup = "zap";
          upgrade = true;
        };
        casks = if work.enable then casks.all_work else casks.all_personal;
        # masApps = {
        #   Wireguard = 1451685025;
        # };
        extraConfig = "";
      };
  };
}
