{ config, pkgs, ... }:
let
  pinned = import ../default.nix { };

  hm = with builtins; fromJSON (readFile ../sources/home-manager.json);
  home-manager = fetchTarball {
    inherit (hm) sha256;
    url = "https://github.com/nix-community/home-manager/archive/${hm.rev}.tar.gz";
  };
  nd = with builtins; fromJSON (readFile ../sources/darwin.json);
  nix-darwin = fetchTarball {
    inherit (nd) sha256;
    url = "https://github.com/LnL7/nix-darwin/archive/${nd.rev}.tar.gz";
  };
  jacobi = import ../home.nix;
in
{
  inherit home-manager jacobi nix-darwin pinned;

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      max-jobs = auto
      narinfo-cache-negative-ttl = 10
      extra-experimental-features = nix-command flakes
      extra-substituters = https://jacobi.cachix.org
      extra-trusted-public-keys = jacobi.cachix.org-1:JJghCz+ZD2hc9BHO94myjCzf4wS3DeBLKHOz3jCukMU=
    '';
    trustedUsers = [ "root" "jacobi" ];
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

    # android
    s21 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLuqazOtTUHVkywIMHWXizCLmSaEl2C8Oyb9t5LmslD jacobi@s21";
    zfold3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuFnEC93wi/fjHE4oAK1A59HkFltRSfHTZelB4AR29u jacobi@zfold3";

    # ios
    ipad = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQhTANgPfe2Xyw14LjxUyhBmVi/7MJwONf99JvmZrIy jacobi-ipad";

    # laptop
    pluto = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgmAVUZdA5QrsCQFYhL0bf+NbXowV9M12PPiwoWRMJK jacobi@pluto";
    work = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIlB0yckw0Q9WV3/C/teeOn+McN5vJRsuCqKH4b9zm4W Jacobi Petrucciani (gitlab.medable.com)";
    m1max = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJnJ2nh4yutW5Xq11Cp4wdJUU+dJxeNZn9SZsHAj9TRg jacobi@m1max";

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
    ];

    mobile = android ++ ios;

    laptop = [
      pluto
      work
      m1max
    ];

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
      Defaults env_keep+=NIXOS_CONFIG
      Defaults env_keep+=NIXDARWIN_CONFIG
    '';
    wheelNeedsPassword = false;
  };

  services = {
    tailscale.enable = true;
    netdata.enable = true;
    openssh = {
      enable = true;
      passwordAuthentication = false;
      permitRootLogin = "no";
      forwardX11 = true;
    };
  };

  timeZone = "America/Indiana/Indianapolis";

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };
}
