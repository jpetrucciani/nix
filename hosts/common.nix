{ pkgs, ... }:
let
  inherit (pkgs.stdenv) isDarwin isLinux isAarch64;
  isM1 = isDarwin && isAarch64;
  isOldMac = isDarwin && !isAarch64;
  isNixOS = isLinux && (builtins.match ".*ID=nixos.*" (builtins.readFile /etc/os-release)) == [ ];
  isAndroid = isAarch64 && !isDarwin && !isNixOS;
  isUbuntu = isLinux && (builtins.match ".*ID=ubuntu.*" (builtins.readFile /etc/os-release)) == [ ];
  isNixDarwin = pkgs.getEnv "NIXDARWIN_CONFIG" != "";

  pinned = import ../default.nix { };

  hm = with builtins; fromJSON (readFile ../sources/home-manager.json);
  home-manager = import
    (fetchTarball {
      inherit (hm) sha256;
      url = "https://github.com/nix-community/home-manager/archive/${hm.rev}.tar.gz";
    })
    { pkgs = pinned; };
  nd = with builtins; fromJSON (readFile ../sources/darwin.json);
  nix-darwin = fetchTarball {
    inherit (nd) sha256;
    url = "https://github.com/LnL7/nix-darwin/archive/${nd.rev}.tar.gz";
  };

  mms = import
    (fetchTarball {
      url = "https://github.com/mkaito/nixos-modded-minecraft-servers/archive/68f2066499c035fd81c9dacfea2f512d6b0b62e5.tar.gz";
      sha256 = "1nmw497ahb9hjjh0kwr1z782q41gcw5kw4dl4alg8pnyhgq141r1";
    });

  jacobi = import ../home.nix;

  attrIf = check: name: if check then name else null;
in
{
  inherit home-manager jacobi nix-darwin mms pinned;

  nix = {
    extraOptions = ''
      max-jobs = auto
      narinfo-cache-negative-ttl = 10
      extra-experimental-features = nix-command flakes
      extra-substituters = https://jacobi.cachix.org https://digitallyinduced.cachix.org
      extra-trusted-public-keys = jacobi.cachix.org-1:JJghCz+ZD2hc9BHO94myjCzf4wS3DeBLKHOz3jCukMU= digitallyinduced.cachix.org-1:y+wQvrnxQ+PdEsCt91rmvv39qRCYzEgGQaldK26hCKE=
    '';
    settings = {
      trusted-users = [ "root" "jacobi" ];
    };
  };

  extraGroups = [ "wheel" "networkmanager" "docker" "podman" ];

  sysctl_opts = {
    "fs.inotify.max_user_watches" = 1048576;
    "fs.inotify.max_queued_events" = 1048576;
    "fs.inotify.max_user_instances" = 1048576;
    "net.core.rmem_max" = 2500000;
  };

  defaultLocale = "en_US.UTF-8";
  extraLocaleSettings = let utf8 = "en_US.UTF-8"; in
    {
      LC_ADDRESS = utf8;
      LC_IDENTIFICATION = utf8;
      LC_MEASUREMENT = utf8;
      LC_MONETARY = utf8;
      LC_NAME = utf8;
      LC_NUMERIC = utf8;
      LC_PAPER = utf8;
      LC_TELEPHONE = utf8;
      LC_TIME = utf8;
    };

  env = { };

  emails = {
    personal = "j@cobi.dev";
    work = "jacobi.petrucciani@medable.com";
  };

  pubkeys = rec {
    # physical
    galaxyboss = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO9u9+khlywG0vSsrTsdjZEhKlKBpXx8RnwESGw+zIKI galaxyboss";
    megaboss = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEhhl/jKYcglH7+tTYgsVRKqVuf7hwF6yOgpdYIQWAyJ jacobi-megaboss";

    # servers
    hyperion = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICO5xk+gAyX4aKH7jpVDCIanXhezhK7XuaFOSJY+Xf1k jacobi@hyperion";
    tethys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAKqBsfhg4qbm3/aXV+6hy2oaWqouT63MDkwNc6E3pwd jacobi@tethys";
    mimas = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIbBo1RRXmMm8GBVzaoM27hgoMuNB+bsXJLSUj6xuxEQ armboss";
    titan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDKnCuUSP/RbAfUvNkD43wm6w5dhsfdIgSqawj9Z0UQX jacobi@titan";
    jupiter = "";
    saturn = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPY2sNJE5ysSTeFzTv2U+zIeIB5LMhbUaP+yC5VDgEHD jacobi@saturn";
    home = "";
    neptune = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqXt2116T/hpMpdmlh3QquPcF/COXPtJS4BkjwECf++ jacobi@neptune";
    charon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIQf/+Cw19PwfLGRs7VyJR9rqwglDG/ZwBbwJY1Aagxo jacobi@charon";
    mars = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBMW7fOdfDeI+9TwYHPUzApYDlNFOfLkl9NC06Du23mP jacobi@mars";
    phobos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7CSn6s/Wuxa2sC4NXCIXGvX3oz8BN1vsyaZGd3wJED jacobi@phobos";
    luna = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOoY9vE2hPcBtoI/sE9pmk4ocO+QWZv2lvtxcPs9oha jacobi@luna";
    milkyway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2VPpmvMVt+5LHJfgmsTSdWy5SIM2gBvgpyuT3iMt1a jacobi@milkyway";

    # android
    s21 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLuqazOtTUHVkywIMHWXizCLmSaEl2C8Oyb9t5LmslD jacobi@s21";
    zfold3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuFnEC93wi/fjHE4oAK1A59HkFltRSfHTZelB4AR29u jacobi@zfold3";

    # ios
    ipad = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQhTANgPfe2Xyw14LjxUyhBmVi/7MJwONf99JvmZrIy jacobi-ipad";
    iphone13 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyzxXyPhjpAMWSqsJQs/W3IAI+si6y7PUKxckihPynW jacobi@iphone13";

    # laptops
    pluto = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgmAVUZdA5QrsCQFYhL0bf+NbXowV9M12PPiwoWRMJK jacobi@pluto";
    ymir = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJu8erBI/BUNkvQR4OC+1Q8zrpVzI4NyAufuXieWshQk jacobi@ymir";
    m1max = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJnJ2nh4yutW5Xq11Cp4wdJUU+dJxeNZn9SZsHAj9TRg jacobi@m1max";
    andromeda = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL5IQw8Fxc+IXIUTfwka558rzb67bpprt4Q1g6V133Ok jacobi@andromeda";
    # nix-daemon on laptops
    nix-m1max = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIwkBMOku4AYYQsWIX1IZdX9azpEgfVXp6uHEYGUbM3K nix@m1max";

    # hms deploy
    hms = ''command="bash -lc '/home/jacobi/.nix-profile/bin/hms'" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBJffkD9CKA/sfuBnT4BOb3XZvW0XuLDiyJ+cjdIctq1 jacobi@hms'';

    desktop = [
      galaxyboss
      megaboss
    ];

    server = [
      neptune
      saturn
      titan
      tethys
      hyperion
      mimas
      jupiter
      home
    ];

    android = [
      s21
      zfold3
    ];

    ios = [
      ipad
      iphone13
    ];

    mobile = android ++ ios;

    laptop = [
      pluto
      m1max
      andromeda
    ];

    usual = [
      galaxyboss
      pluto
      hms
    ] ++ mobile;
    all = desktop ++ server ++ mobile ++ laptop;
  };

  swapDevices = [{ device = "/swapfile"; size = 1024; }];

  security.sudo = {
    extraRules = [
      {
        users = [ "jacobi" ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
    extraConfig = ''
      Defaults env_keep+=NIX_HOST
      Defaults env_keep+=NIXOS_CONFIG
      Defaults env_keep+=NIXDARWIN_CONFIG
    '';
    wheelNeedsPassword = false;
  };

  _services = {
    blocky = {
      enable = true;
      # settings: https://0xerr0r.github.io/blocky/configuration
      settings = {
        blocking = {
          blackLists = {
            ads = [
              "http://sysctl.org/cameleon/hosts"
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
              "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
              "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
            ];
            special = [
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts"
            ];
          };
          blockTTL = "1m";
          blockType = "zeroIp";
          clientGroupsBlock = {
            default = [
              "ads"
              "special"
            ];
          };
          downloadAttempts = 5;
          downloadCooldown = "10s";
          downloadTimeout = "4m";
          refreshPeriod = "4h";
          startStrategy = "failOnError";
          whiteLists = {
            ads = [
            ];
          };
        };
        bootstrapDns = "tcp+udp:1.1.1.1";
        caching = {
          cacheTimeNegative = "30m";
          maxItemsCount = 0;
          maxTime = "30m";
          minTime = "5m";
          prefetchExpires = "2h";
          prefetchMaxItemsCount = 0;
          prefetchThreshold = 5;
          prefetching = true;
        };
        clientLookup = {
          clients = {
            luna = [
              "192.168.1.44"
            ];
          };
          singleNameOrder = [
            2
            1
          ];
        };
        conditional = {
          fallbackUpstream = false;
          mapping = { };
          rewrite = { };
        };
        connectIPVersion = "dual";
        customDNS = {
          customTTL = "1h";
          filterUnmappedTypes = true;
          mapping = {
            "cobi" = "192.168.1.44";
            "milkyway.cobi" = "192.168.1.40";
            "titan.cobi" = "192.168.1.41";
            "luna.cobi" = "192.168.1.44";
            "jupiter.cobi" = "192.168.1.69";
            "charon.cobi" = "192.168.1.71";
            "pluto.cobi" = "192.168.1.100";
            "phobos.cobi" = "192.168.1.134";
            "neptune.cobi" = "100.101.139.41";
          };
          rewrite = { };
        };
        ede = {
          enable = true;
        };
        filtering = {
          queryTypes = [
            "AAAA"
          ];
        };
        hostsFile = {
          filePath = "/etc/hosts";
          filterLoopback = true;
          hostsTTL = "60m";
          refreshPeriod = "30m";
        };
        httpPort = 4000;
        logFormat = "text";
        logLevel = "info";
        logPrivacy = false;
        logTimestamp = true;
        minTlsServeVersion = 1.3;
        port = 53;
        prometheus = {
          enable = true;
          path = "/metrics";
        };
        # queryLog = {
        # creationAttempts = 1;
        # creationCooldown = "2s";
        # logRetentionDays = 28;
        # target = "/var/log/blocky/";
        # type = "console";
        # };
        startVerifyUpstream = true;
        upstream = {
          default = [
            "1.1.1.1"
          ];
        };
        upstreamTimeout = "2s";
      };
    };
  };
  services = {
    tailscale.enable = true;
    netdata.enable = true;
    openssh = {
      enable = true;
      passwordAuthentication = false;
      permitRootLogin = "no";
      forwardX11 = true;
      kexAlgorithms = [
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
      ];
      ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
        # "aes128-gcm@openssh.com"
        "aes256-ctr"
        # "aes192-ctr"
        # "aes128-ctr"
      ];
      macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
      ];
    };
  };

  mac = {
    apps = {
      Wireguard = 1451685025;
      Poolside = 1514817810;
    };
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
      "sshfs"
      "qemu"
    ];
    casks = rec {
      fonts = [
        "font-caskaydia-cove-nerd-font"
        "font-fira-code-nerd-font"
        "font-hasklug-nerd-font"
      ];
      fun = [
        "epic-games"
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
      all_personal = pkgs.lib.lists.subtractLists work all;
      all_work = pkgs.lib.lists.subtractLists fun all;
    };
  };

  timeZone = "America/Indiana/Indianapolis";

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };

  ports = rec {
    usual = [
      ssh
      http
      https
    ];
    ssh = 22;
    http = 80;
    https = 443;
    n8n = 5678;
    jellyfin = 8096;
    home-assistant = 8123;
    netdata = 19999;
    plex = 32400;
  };

  minecraft = {
    conf = {
      jre8 = pkgs.temurin-bin-8;
      jre17 = pkgs.temurin-bin-17;
      jre18 = pkgs.temurin-bin-18;
      jre19 = pkgs.temurin-bin-19;

      jvmOpts = builtins.concatStringsSep " " [
        "-XX:+UseG1GC"
        "-XX:+ParallelRefProcEnabled"
        "-XX:MaxGCPauseMillis=200"
        "-XX:+UnlockExperimentalVMOptions"
        "-XX:+DisableExplicitGC"
        "-XX:+AlwaysPreTouch"
        "-XX:G1NewSizePercent=40"
        "-XX:G1MaxNewSizePercent=50"
        "-XX:G1HeapRegionSize=16M"
        "-XX:G1ReservePercent=15"
        "-XX:G1HeapWastePercent=5"
        "-XX:G1MixedGCCountTarget=4"
        "-XX:InitiatingHeapOccupancyPercent=20"
        "-XX:G1MixedGCLiveThresholdPercent=90"
        "-XX:G1RSetUpdatingPauseTimePercent=5"
        "-XX:SurvivorRatio=32"
        "-XX:+PerfDisableSharedMem"
        "-XX:MaxTenuringThreshold=1"
      ];

      defaults = {
        white-list = false;
        spawn-protection = 0;
        max-tick-time = 5 * 60 * 1000;
        allow-flight = true;
      };
    };
  };
}
