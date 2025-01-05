let
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
    charon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIQf/+Cw19PwfLGRs7VyJR9rqwglDG/ZwBbwJY1Aagxo jacobi@charon";
    mars = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBMW7fOdfDeI+9TwYHPUzApYDlNFOfLkl9NC06Du23mP jacobi@mars";
    phobos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7CSn6s/Wuxa2sC4NXCIXGvX3oz8BN1vsyaZGd3wJED jacobi@phobos";
    polaris = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKkq80OeQLD7QBlE81EYUC+ZOgNZT1+Vc8oGP6y3mTFm jacobi@polaris";
    luna = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOoY9vE2hPcBtoI/sE9pmk4ocO+QWZv2lvtxcPs9oha jacobi@luna";
    milkyway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2VPpmvMVt+5LHJfgmsTSdWy5SIM2gBvgpyuT3iMt1a jacobi@milkyway";
    terra = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFWWDYzXHtB3hd/5sWeg+kz+COGxCEWalspwCNnZNOZz jacobi@terra";
    nyx0 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIg9CfLq9fHbwfg16W2k8A9rXw7AUGQWDk4qwikDrikj jacobi@nyx0";
    styx = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3gO1YSpzqJ5aheyC/gx53lK9Wu21dA88+VrvPqMoRD jacobi@styx";

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

    desktop = [
      galaxyboss
      megaboss
    ];

    server = [
      saturn
      neptune
      charon
      phobos
      luna
      milkyway
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
      pluto
      proteus
    ] ++ mobile;
    all = desktop ++ server ++ mobile ++ laptop;
  };
  _base_nix_options = ''
    max-jobs = auto
    narinfo-cache-negative-ttl = 10
    extra-experimental-features = nix-command flakes
  '';
  subs = {
    jacobi = {
      url = "https://jacobi.cachix.org";
      key = "jacobi.cachix.org-1:JJghCz+ZD2hc9BHO94myjCzf4wS3DeBLKHOz3jCukMU=";
    };
    be = {
      url = "https://blackedge-nix.s3.us-east-2.amazonaws.com";
      key = "blackedge-nix.s3.us-east-2.amazonaws.com:1MDUZHbXmD18H1RJYRo7Fy4prdg+xjyyKm8CUjrOj5w=";
    };
    cuda = {
      url = "https://cuda-maintainers.cachix.org";
      key = "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E=";
    };
  };
in
{
  inherit ports pubkeys;
  nix = {
    extraOptions = ''
      ${_base_nix_options}
      extra-substituters = ${subs.jacobi.url}
      extra-trusted-public-keys = ${subs.jacobi.key}
    '';
    settings.trusted-users = [ "root" "jacobi" ];
  };
  nix-be = {
    extraOptions = ''
      ${_base_nix_options}
      extra-substituters = ${subs.jacobi.url} ${subs.be.url}
      extra-trusted-public-keys = ${subs.jacobi.key} ${subs.be.key}
    '';
    settings.trusted-users = [ "root" "jacobi" ];
  };
  nix-cuda = {
    extraOptions = ''
      ${_base_nix_options}
      extra-substituters = ${subs.jacobi.url} ${subs.cuda.url}
      extra-trusted-public-keys = ${subs.jacobi.key} ${subs.cuda.key}
    '';
    settings.trusted-users = [ "root" "jacobi" ];
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
        terra_ts = "100.88.176.6";
        ben = "192.168.69.20";
        bedrock = "192.168.69.70";
        granite = "192.168.69.72";
        jupiter = "100.84.224.73";
        neptune = "100.101.139.41";
        edge = "100.69.215.126";
        luna = "100.78.40.10";
        milkyway = "100.83.252.130";
        styx = "100.102.221.30";
        phobos = "100.116.153.116";
        mercury = "100.92.180.69";
        polaris = "100.65.145.59";
        titan = "100.66.137.28";
      in
      ''
        ${terra} api.cobi.dev
        ${terra} auth.cobi.dev
        ${terra} search.cobi.dev
        ${terra} searxng.cobi.dev
        ${terra} broadsword.tech
        ${terra} cobi.dev
        ${terra} hexa.dev
        ${terra} invoice.cobi.dev
        ${terra} nix.cobi.dev
        ${terra} ntfy.cobi.dev
        ${terra} oc.cobi.dev
        ${terra} otf.cobi.dev
        ${terra} terra
        ${terra} vault.cobi.dev
        ${terra} x.hexa.dev
        ${terra} z.cobi.dev
        ${terra_ts} llm.cobi.dev
        ${ben} ben
        ${bedrock} bedrock
        ${granite} granite
        ${edge} edge
        ${jupiter} jupiter
        ${luna} luna
        ${neptune} neptune
        ${milkyway} milkyway
        ${styx} styx
        ${mercury} mercury
        ${phobos} phobos
        ${polaris} polaris
        ${titan} titan
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
    promtail =
      { hostname
      , loki_ip ? "100.78.40.10"
      , promtail_port ? ports.promtail
      , loki_port ? ports.loki
      , extra_scrape_configs ? [ ]
      }: {
        enable = true;
        configuration = {
          server = {
            http_listen_port = promtail_port;
            grpc_listen_port = 0;
          };
          positions = {
            filename = "/tmp/positions.yaml";
          };
          clients = [{
            url = "http://${loki_ip}:${toString loki_port}/loki/api/v1/push";
          }];
          scrape_configs = [{
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = hostname;
              };
            };
            relabel_configs = [{
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }];
          }] ++ extra_scrape_configs;
        };
      };
    promtail_scrapers = {
      caddy = { path ? "/var/log/caddy/*.log" }: {
        job_name = "caddy";
        static_configs = [{ targets = [ "localhost" ]; labels = { job = "caddylogs"; __path__ = path; }; }];
      };
    };
    prometheus_exporters = _: {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = ports.prometheus_node_exporter;
      };
      systemd.enable = true;
    };
  };
}
