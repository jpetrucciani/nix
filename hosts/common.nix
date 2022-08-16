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
  jacobi = import ../home.nix;

  attrIf = check: name: if check then name else null;
in
{
  inherit home-manager jacobi nix-darwin pinned;

  nix = {
    extraOptions = ''
      max-jobs = auto
      narinfo-cache-negative-ttl = 10
      extra-experimental-features = nix-command flakes
      extra-substituters = https://jacobi.cachix.org
      extra-trusted-public-keys = jacobi.cachix.org-1:JJghCz+ZD2hc9BHO94myjCzf4wS3DeBLKHOz3jCukMU=
    '';
    ${attrIf isDarwin "trustedUsers"} = [ "root" ];
    ${attrIf isNixOS "settings"} = {
      trusted-users = [ "root" ];
    };
  };

  extraGroups = [ "wheel" "networkmanager" "docker" "podman" ];

  env = {
    CHARM_HOST = "charm.cobi.dev";
    CHARM_HTTP_PORT = "443";
  };

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

    # android
    s21 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLuqazOtTUHVkywIMHWXizCLmSaEl2C8Oyb9t5LmslD jacobi@s21";
    zfold3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuFnEC93wi/fjHE4oAK1A59HkFltRSfHTZelB4AR29u jacobi@zfold3";

    # ios
    ipad = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQhTANgPfe2Xyw14LjxUyhBmVi/7MJwONf99JvmZrIy jacobi-ipad";
    iphone13 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyzxXyPhjpAMWSqsJQs/W3IAI+si6y7PUKxckihPynW jacobi@iphone13";

    # laptops
    pluto = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgmAVUZdA5QrsCQFYhL0bf+NbXowV9M12PPiwoWRMJK jacobi@pluto";
    m1max = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJnJ2nh4yutW5Xq11Cp4wdJUU+dJxeNZn9SZsHAj9TRg jacobi@m1max";
    andromeda = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKbNra2GRSa3/JSDLBM1b8l4kIMA28XMyBUAJKJ5zFby jacobi@andromeda";

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

  services = {
    tailscale.enable = true;
    netdata.enable = true;
    # dictd = {
    #   enable = true;
    #   DBs = with pkgs.dictdDBs; [ wiktionary wordnet ];
    # };
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
        "notion"
        "osxfuse"
        "parsec"
        "qlvideo"
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
    jellyfin = 8096;
    home-assistant = 8123;
    netdata = 19999;
    plex = 32400;
  };
}
