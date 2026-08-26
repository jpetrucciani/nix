let
  machines = {
    nixos = [
      "cy1-nix-01"
      "edge"
      "luna"
      "milkyway"
      "voyager"
      "mars"
      "neptune"
      "phobos"
      "polaris"
      "terra"
      "titan"
    ];
    darwin = [
      "m1max"
      "nyx0"
      "pluto"
      "styx"
    ];
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
    nfs = 2049;
    grafana = 3000;
    loki = 3100;
    n8n = 5678;
    gradio = 7860;
    jellyfin = 8096;
    home-assistant = 8123;
    prometheus = 9001;
    prometheus_node_exporter = 9002;
    promtail = 9080;
    netdata = 19999;
    plex = 32400;
  };
  pubkeys = rec {
    # physical
    galaxyboss = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO9u9+khlywG0vSsrTsdjZEhKlKBpXx8RnwESGw+zIKI galaxyboss";
    megaboss = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEhhl/jKYcglH7+tTYgsVRKqVuf7hwF6yOgpdYIQWAyJ jacobi-megaboss";
    titan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKNU+ZU3kZNtBPGZ0v8XB8eN491OBsgSY+pDCtUFI4Y8 jacobi@titan";

    # servers
    # jupiter = "";
    saturn = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPY2sNJE5ysSTeFzTv2U+zIeIB5LMhbUaP+yC5VDgEHD jacobi@saturn";
    neptune = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqXt2116T/hpMpdmlh3QquPcF/COXPtJS4BkjwECf++ jacobi@neptune";
    mars = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK+iFCAHMWtKEltX5iJZt7fwyB8xaw5zPFosELp122eN jacobi@mars";
    phobos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7CSn6s/Wuxa2sC4NXCIXGvX3oz8BN1vsyaZGd3wJED jacobi@phobos";
    polaris = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKkq80OeQLD7QBlE81EYUC+ZOgNZT1+Vc8oGP6y3mTFm jacobi@polaris";
    luna = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOoY9vE2hPcBtoI/sE9pmk4ocO+QWZv2lvtxcPs9oha jacobi@luna";
    milkyway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2VPpmvMVt+5LHJfgmsTSdWy5SIM2gBvgpyuT3iMt1a jacobi@milkyway";
    terra = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFWWDYzXHtB3hd/5sWeg+kz+COGxCEWalspwCNnZNOZz jacobi@terra";
    nyx0 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIg9CfLq9fHbwfg16W2k8A9rXw7AUGQWDk4qwikDrikj jacobi@nyx0";
    styx = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3gO1YSpzqJ5aheyC/gx53lK9Wu21dA88+VrvPqMoRD jacobi@styx";
    mercury = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLAJdW+XxljUGrFMXJdc1ULVYOYR+/aeEddl+7mjOCG jacobi@mercury";
    voyager = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIIejYkuLdJ3OslVRfKfr9w+MUfhAvRhoM2agNdxlTn/ jacobi@voyager";

    # android
    s21 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLuqazOtTUHVkywIMHWXizCLmSaEl2C8Oyb9t5LmslD jacobi@s21";

    # ios
    ipad = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQhTANgPfe2Xyw14LjxUyhBmVi/7MJwONf99JvmZrIy jacobi-ipad";
    iphone15 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyzxXyPhjpAMWSqsJQs/W3IAI+si6y7PUKxckihPynW jacobi@iphone13";

    # laptops
    pluto = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgmAVUZdA5QrsCQFYhL0bf+NbXowV9M12PPiwoWRMJK jacobi@pluto";
    m1max = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJnJ2nh4yutW5Xq11Cp4wdJUU+dJxeNZn9SZsHAj9TRg jacobi@m1max";
    andromeda = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBRLoe5SoO2nipGJw6QLRRLOyfiKtmi2lvnlCQtLz7o4 jacobi@andromeda";
    # nix-daemon on laptops
    nix-m1max = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIwkBMOku4AYYQsWIX1IZdX9azpEgfVXp6uHEYGUbM3K nix@m1max";
    proteus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOgeFDVOG+pFwyd9p3jSbmS7N8+kdtf4l6QdAIT8q+Ps jacobi@proteus";

    # edge
    edge = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILkME8cVp908fLcQiSYmwSruCBcm4iBR8CS87s8AqNmK jacobi@edge";
    edgewin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRFawIUexIkAJ6yovZIJjz/AvWuZLCwTAp4I1Wv5afY jacobi@edgewin";
    hub2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPC6SkLgq4GVlyskAEih+B3aCrIB5PczUOmokdhKSZLC jacobi@hub2";
    cy1-nix-01 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhEenjqGEiybWJZFYcaPSLNbcufZga6TRQ6Um3v5Kwy jacobi@cy1-nix-01";

    desktop = [
      galaxyboss
      megaboss
    ];

    server = [
      saturn
      neptune
      phobos
      luna
      milkyway
      voyager
      styx
      terra
      titan
    ];

    android = [
      s21
    ];

    ios = [
      ipad
      iphone15
    ];

    mobile = android ++ ios;

    laptop = [
      pluto
      m1max
      andromeda
    ];

    usual = [
      galaxyboss
      milkyway
      voyager
      pluto
      proteus
    ] ++ mobile;
    all = desktop ++ server ++ mobile ++ laptop;
  };
  subs = {
    nix-community = {
      url = "https://nix-community.cachix.org";
      key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    };
    g7c = {
      url = "https://cache.g7c.us";
      key = "cache.g7c.us:dSWpE2B5zK/Fahd7npIQWM4izRnVL+a4LiCAnrjdoFY=";
    };
    be = {
      url = "https://blackedge-nix.s3.us-east-2.amazonaws.com";
      key = "blackedge-nix.s3.us-east-2.amazonaws.com:1MDUZHbXmD18H1RJYRo7Fy4prdg+xjyyKm8CUjrOj5w=";
    };
    medable = {
      url = "https://medable-nix.s3.us-west-1.amazonaws.com";
      key = "medable-nix.s3.us-west-1.amazonaws.com:dtdREarYUM5iVkNgmcJyL1aYfzVL2Pgfq4a5godxCVk=";
    };
  };
  ghFlake = { owner, repo }: {
    to = {
      inherit owner repo;
      type = "github";
    };
  };
  jacobi = repo: ghFlake { inherit repo; owner = "jpetrucciani"; };
  mkNix = extraSubs:
    let
      allSubs = [ subs.g7c ] ++ extraSubs;
    in
    {
      settings = {
        max-jobs = "auto";
        keep-going = true;
        trusted-users = [ "root" "jacobi" ];
        extra-experimental-features = [ "nix-command" "flakes" ];
        narinfo-cache-negative-ttl = 10;
        extra-substituters = map (s: s.url) allSubs;
        extra-trusted-public-keys = map (s: s.key) allSubs;
      };
      registry = {
        j = jacobi "nix";
        hex = jacobi "hex";
        pog = jacobi "pog";
      };
    };
  hostRecords = {
    proxmox =
      let
        terra_lan = "192.168.69.10";
      in
      {
        "api.cobi.dev" = terra_lan;
        "auth.cobi.dev" = terra_lan;
        "broadsword.tech" = terra_lan;
        "cobi.dev" = terra_lan;
        "hexa.dev" = terra_lan;
        "invoice.cobi.dev" = terra_lan;
        "nix.cobi.dev" = terra_lan;
        "ntfy.cobi.dev" = terra_lan;
        "oc.cobi.dev" = terra_lan;
        "otf.cobi.dev" = terra_lan;
        "search.cobi.dev" = terra_lan;
        "searxng.cobi.dev" = terra_lan;
        "vault.cobi.dev" = terra_lan;
        "x.hexa.dev" = terra_lan;
        "z.cobi.dev" = terra_lan;
        bedrock = "192.168.69.70";
        ben = "192.168.69.20";
        granite = "192.168.69.72";
        terra = terra_lan;
      };
    tailnet =
      let
        terra_traefik = "100.88.33.20";
      in
      {
        "chat.cobi.dev" = terra_traefik;
        "google-mcp.cobi.dev" = terra_traefik;
        "grafana.cobi.dev" = terra_traefik;
        "llm.cobi.dev" = "100.88.176.6";
        "lobe.cobi.dev" = terra_traefik;
        "loki-internal.cobi.dev" = terra_traefik;
        "mcpo.cobi.dev" = terra_traefik;
        "n8n.cobi.dev" = terra_traefik;
        "ntfy-mcp.cobi.dev" = terra_traefik;
        "o.cobi.dev" = terra_traefik;
        "quest.cobi.dev" = terra_traefik;
        "searxng.cobi.dev" = terra_traefik;
        cy1-nix-01 = "100.127.34.123";
        edge = "100.69.215.126";
        jupiter = "100.84.224.73";
        luna = "100.78.40.10";
        mercury = "100.92.180.69";
        milkyway = "100.83.252.130";
        neptune = "100.101.139.41";
        phobos = "100.116.153.116";
        polaris = "100.65.145.59";
        styx = "100.102.221.30";
        terra = "100.88.176.6";
        titan = "100.66.137.28";
      };
  };
  renderHosts = records:
    builtins.concatStringsSep "\n" (builtins.attrValues (builtins.mapAttrs (name: value: "${value} ${name}") records)) + "\n";
in
{
  inherit hostRecords ports pubkeys machines subs;
  nix = mkNix [ ];
  nix-be = mkNix [ subs.be ];
  nix-cuda = mkNix [ subs.nix-community ];

  sysctl_opts = {
    "fs.inotify.max_user_watches" = 1048576;
    "fs.inotify.max_queued_events" = 1048576;
    "fs.inotify.max_user_instances" = 1048576;
    "net.core.rmem_max" = 2500000;
  };

  extraHosts = builtins.mapAttrs (_: renderHosts) hostRecords;

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

  timeZone = "America/Indiana/Indianapolis";
  tz = {
    home = "America/Indiana/Indianapolis";
    work = "America/Chicago";
  };

  caddy = {
    security = ''
      (SECURITY) {
        encode zstd gzip
        header {
          -Server
          Strict-Transport-Security "max-age=31536000; include-subdomains;"
          X-XSS-Protection "1; mode=block"
          X-Frame-Options "DENY"
          X-Content-Type-Options nosniff
          Referrer-Policy  no-referrer-when-downgrade
          X-Robots-Tag "none"
        }
      }

    '';
  };

  templates = {
    prometheus_exporters = _: {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = ports.prometheus_node_exporter;
      };
      systemd.enable = true;
    };
  };

  bash_funcs = {
    wezterm_title = ''
      __wezterm_title() {
        local last_rc="$1"
        local user_host="''${USER}@''${HOSTNAME%%.*}"
        local cwd="''${PWD/#$HOME/\~}"
        local git_branch=""
        local venv=""
        local k8s=""

        # git branch (reads .git/HEAD directly — no subprocess)
        if [ -f .git/HEAD ]; then
          git_branch=$(sed 's|ref: refs/heads/||' .git/HEAD 2>/dev/null)
        elif [ -d .git ]; then
          # detached HEAD
          git_branch=$(git rev-parse --short HEAD 2>/dev/null)
        fi

        # python venv
        if [ -n "$VIRTUAL_ENV" ]; then
          venv=$(basename "$VIRTUAL_ENV")
        fi

        # k8s context (only if KUBECONFIG is set — avoids slow kubectl calls)
        if [ -n "$KUBECONFIG" ] && command -v kubectl &>/dev/null; then
          k8s=$(kubectl config current-context 2>/dev/null)
        fi

        # build title: base part
        local title="''${user_host}: ''${cwd}"

        # append optional tags
        [ -n "$git_branch" ]          && title="''${title}|git:''${git_branch}"
        [ -n "$venv" ]                && title="''${title}|venv:''${venv}"
        [ -n "$k8s" ]                 && title="''${title}|k8s:''${k8s}"
        [ "$last_rc" != "0" ]         && title="''${title}|rc:''${last_rc}"

        # set terminal title via OSC 0
        echo -ne "\033]0;''${title}\007"
      }

      # starship owns PROMPT_COMMAND outright, so hook its documented precmd slot
      # instead of fighting it. Without starship, prepend so $? is still intact.
      if [ -n "''${STARSHIP_SHELL:-}" ] || command -v starship >/dev/null 2>&1; then
        starship_precmd_user_func="__wezterm_title"
      else
        case "$PROMPT_COMMAND" in
          *__wezterm_title*) ;;
          *) PROMPT_COMMAND="__wezterm_title''${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
        esac
      fi
    '';
  };
}
