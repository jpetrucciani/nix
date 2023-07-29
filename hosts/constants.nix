{
  nix = {
    extraOptions = ''
      max-jobs = auto
      narinfo-cache-negative-ttl = 10
      extra-experimental-features = nix-command flakes
      extra-substituters = https://jacobi.cachix.org
      extra-trusted-public-keys = jacobi.cachix.org-1:JJghCz+ZD2hc9BHO94myjCzf4wS3DeBLKHOz3jCukMU=
    '';
    settings = {
      trusted-users = [ "root" "jacobi" ];
    };
  };

  sysctl_opts = {
    "fs.inotify.max_user_watches" = 1048576;
    "fs.inotify.max_queued_events" = 1048576;
    "fs.inotify.max_user_instances" = 1048576;
    "net.core.rmem_max" = 2500000;
  };

  extraHosts = {
    proxmox =
      let
        terra = "192.168.69.10";
        ben = "192.168.69.20";
        bedrock = "192.168.69.70";
      in
      ''
        ${terra} terra
        ${terra} cobi.dev
        ${terra} api.cobi.dev
        ${terra} auth.cobi.dev
        ${terra} vault.cobi.dev
        ${terra} nix.cobi.dev
        ${terra} broadsword.tech
        ${terra} hexa.dev
        ${terra} x.hexa.dev
        ${ben} ben
        ${bedrock} bedrock
      '';
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

  name = rec {
    first = "jacobi";
    last = "petrucciani";
    full = "${first} ${last}";
  };

  emails = {
    personal = "j@cobi.dev";
    work = "jpetrucciani@medable.com";
  };

  pubkeys = rec {
    # physical
    galaxyboss = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO9u9+khlywG0vSsrTsdjZEhKlKBpXx8RnwESGw+zIKI galaxyboss";
    megaboss = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEhhl/jKYcglH7+tTYgsVRKqVuf7hwF6yOgpdYIQWAyJ jacobi-megaboss";

    # servers
    bedrock = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyGIL87ScZN4Bir5yxlLendu4Iex2RjrmDRLE3+u7Aq jacobi@bedrock";
    granite = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+Ueb5yUyGWNA71L2If6pwy5AORXO3LN4CzREgwWhO2 jacobi@granite";
    titan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDKnCuUSP/RbAfUvNkD43wm6w5dhsfdIgSqawj9Z0UQX jacobi@titan";
    jupiter = "";
    saturn = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPY2sNJE5ysSTeFzTv2U+zIeIB5LMhbUaP+yC5VDgEHD jacobi@saturn";
    neptune = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqXt2116T/hpMpdmlh3QquPcF/COXPtJS4BkjwECf++ jacobi@neptune";
    charon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIQf/+Cw19PwfLGRs7VyJR9rqwglDG/ZwBbwJY1Aagxo jacobi@charon";
    mars = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBMW7fOdfDeI+9TwYHPUzApYDlNFOfLkl9NC06Du23mP jacobi@mars";
    phobos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7CSn6s/Wuxa2sC4NXCIXGvX3oz8BN1vsyaZGd3wJED jacobi@phobos";
    luna = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOoY9vE2hPcBtoI/sE9pmk4ocO+QWZv2lvtxcPs9oha jacobi@luna";
    milkyway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2VPpmvMVt+5LHJfgmsTSdWy5SIM2gBvgpyuT3iMt1a jacobi@milkyway";
    terra = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFWWDYzXHtB3hd/5sWeg+kz+COGxCEWalspwCNnZNOZz jacobi@terra";

    # android
    s21 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLuqazOtTUHVkywIMHWXizCLmSaEl2C8Oyb9t5LmslD jacobi@s21";

    # ios
    ipad = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQhTANgPfe2Xyw14LjxUyhBmVi/7MJwONf99JvmZrIy jacobi-ipad";
    iphone13 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyzxXyPhjpAMWSqsJQs/W3IAI+si6y7PUKxckihPynW jacobi@iphone13";

    # laptops
    pluto = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgmAVUZdA5QrsCQFYhL0bf+NbXowV9M12PPiwoWRMJK jacobi@pluto";
    ymir = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJu8erBI/BUNkvQR4OC+1Q8zrpVzI4NyAufuXieWshQk jacobi@ymir";
    m1max = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJnJ2nh4yutW5Xq11Cp4wdJUU+dJxeNZn9SZsHAj9TRg jacobi@m1max";
    andromeda = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBRLoe5SoO2nipGJw6QLRRLOyfiKtmi2lvnlCQtLz7o4 jacobi@andromeda";
    # nix-daemon on laptops
    nix-m1max = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIwkBMOku4AYYQsWIX1IZdX9azpEgfVXp6uHEYGUbM3K nix@m1max";

    # edge
    edge = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILkME8cVp908fLcQiSYmwSruCBcm4iBR8CS87s8AqNmK jacobi@edge";
    edgewin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRFawIUexIkAJ6yovZIJjz/AvWuZLCwTAp4I1Wv5afY jacobi@edgewin";
    hub2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPC6SkLgq4GVlyskAEih+B3aCrIB5PczUOmokdhKSZLC jacobi@hub2";

    desktop = [
      galaxyboss
      megaboss
    ];

    server = [
      bedrock
      titan
      saturn
      neptune
      charon
      phobos
      luna
      milkyway
      terra
    ];

    android = [
      s21
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
    ] ++ mobile;
    all = desktop ++ server ++ mobile ++ laptop;
  };

  timeZone = "America/Indiana/Indianapolis";
  ports = rec {
    usual = [
      ssh
      http
      https
    ];
    ssh = 22;
    http = 80;
    https = 443;
    nfs = 2049;
    grafana = 3000;
    loki = 3100;
    n8n = 5678;
    jellyfin = 8096;
    home-assistant = 8123;
    prometheus = 9001;
    prometheus_node_exporter = 9002;
    promtail = 9080;
    netdata = 19999;
    plex = 32400;
  };
}
