# This overlay provides a way to build foundry docker images with nix
{ pkgs }:
let
  inherit (pkgs.lib) concatStringsSep optionals;
  nixconf =
    { substituters ? [ "https://jacobi.cachix.org" ]
    , trusted-public-keys ? [ "jacobi.cachix.org-1:JJghCz+ZD2hc9BHO94myjCzf4wS3DeBLKHOz3jCukMU=" ]
    }: ''
      build-users-group = nixbld
      extra-experimental-features = nix-command flakes
      substituters = https://cache.nixos.org/ ${concatStringsSep " " substituters}
      trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= ${concatStringsSep " " trusted-public-keys}
    '';
  _base_pkgs = _pkgs: with _pkgs; [
    deadnix
    delta
    dyff
    fd
    findutils
    git
    gnumake
    gron
    hex
    jq
    just
    moreutils
    nano
    nixup
    nixpkgs-fmt
    openssh
    scc
    skopeo
    statix
    wget
    which
    yq-go
  ];


  foundry =
    let
      inherit (pkgs.lib) toInt;
      _layers = {
        baseLayer = with pkgs.dockerTools; [
          binSh
          caCertificates
          fakeNss
          usrBinEnv
        ];
        coreLayer = with pkgs; [
          bashInteractive
          coreutils
          curl
          gnugrep
          gnused
          jq
          util-linux
        ];
        nixLayer = with pkgs; [ nix ];
      };
      fn = {
        perm =
          { path
          , user ? "user"
          , group ? "user"
          , uid ? "1000"
          , gid ? "1000"
          , regex ? ".*"
          , mode ? "0744"
          }: {
            inherit mode path regex;
            uname = user;
            gname = group;
            uid = toInt uid;
            gid = toInt gid;
          };
      };
      drvs = {
        mkFolders = pkgs.runCommand "folders" { } ''
          mkdir -p $out/tmp
        '';
        mkUser =
          { user ? "user"
          , group ? "user"
          , uid ? "1000"
          , gid ? "1000"
          , extraMkUser ? ""
          , substituters ? [ "https://jacobi.cachix.org" ]
          , trusted-public-keys ? [ "jacobi.cachix.org-1:JJghCz+ZD2hc9BHO94myjCzf4wS3DeBLKHOz3jCukMU=" ]
          }: (pkgs.runCommand "mkUser" { } ''
            mkdir -p $out/etc/pam.d $out/etc/nix
            echo '${nixconf {inherit substituters trusted-public-keys; }}' >$out/etc/nix/nix.conf
            echo '/bin/bash' >$out/etc/shells

            echo "${user}:x:${uid}:${gid}::" >$out/etc/passwd
            echo "${user}:!x:::::::" >$out/etc/shadow

            echo "${group}:x:${gid}:" >$out/etc/group
            echo "${group}:x::" >$out/etc/gshadow

            cat >$out/etc/pam.d/other <<EOF
            account sufficient pam_unix.so
            auth sufficient pam_rootok.so
            password requisite pam_unix.so nullok sha512
            session required pam_unix.so
            EOF

            touch $out/etc/login.defs
            mkdir -p $out/home/${user}
            ${extraMkUser}
          '');
        entrypoint = pkgs.writeShellApplication {
          name = "entrypoint";
          text = ''
            (nix doctor && ls -la /nix) >/tmp/setup 2>&1
            exec "$@"
          '';
        };
      };
    in
    {
      inherit _layers drvs fn;
      __functor = _:
        { name
        , layers
        , env ? [ ]
        , registry ? "ghcr.io/jpetrucciani"
        , author ? "j@cobi.dev"
        , description ? "a foundry_v2 docker image built with nix"
        , hostPkgs ? pkgs
        , enableNix ? true
        , pathsToLink ? [ "/bin" "/etc" "/lib" "/lib64" "/run" "/share" "/tmp" "/usr" ] ++ extraPathsToLink
        , extraPathsToLink ? [ ]
        , sysLayer ? true
        , user ? "user"
        , group ? "user"
        , uid ? "1000"
        , gid ? "1000"
        , substituters ? [ "https://jacobi.cachix.org" ]
        , trusted-public-keys ? [ "jacobi.cachix.org-1:JJghCz+ZD2hc9BHO94myjCzf4wS3DeBLKHOz3jCukMU=" ]
        , extraCopyToRoot ? [ ]
        , extraPerms ? [ ]
        , extraMkUserPaths ? [ ]
        , extraMkUser ? ""
        }:
        let
          inherit (pkgs.nix2container.nix2container) buildLayer;
          allLayers = with _layers; [ baseLayer ] ++ (optionals sysLayer [ coreLayer ]) ++ (optionals enableNix [ nixLayer ]) ++ layers;
          mkUser = drvs.mkUser {
            inherit user group uid gid substituters trusted-public-keys;
            extraMkUser =
              if enableNix then ''
                mkdir -p $out/home/${user}/.nix-defexpr/channels
                ln -s ${pkgs.path} $out/home/${user}/.nix-defexpr/channels/nixpkgs
                ${extraMkUser}
              '' else extraMkUser;
          };
        in
        hostPkgs.nix2container.nix2container.buildImage {
          name = "${registry}/${name}";
          config = {
            Entrypoint = if enableNix then [ "${drvs.entrypoint}/bin/entrypoint" ] else [ "${pkgs.bash}/bin/bash" "-c" ];
            Env =
              let
                base_path = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
              in
              env ++ [
                "USER=${user}"
                "HOME=/home/${user}"
                "FOUNDRY=3"
              ] ++ (if enableNix then [
                "NIX_PAGER=cat"
                "NIX_PATH=nixpkgs=${pkgs.path}"
                "PATH=/home/user/.local/state/nix/profiles/profile/bin:${base_path}"
              ] else [
                "PATH=${base_path}"
              ]);
            Labels = let _base = "org.opencontainers.image"; in {
              "${_base}.source" = "https://github.com/jpetrucciani/nix";
              "${_base}.title" = name;
              "${_base}.authors" = author;
              "${_base}.description" = description;
            };
            User = user;
            WorkingDir = "/home/${user}";
          };
          copyToRoot = [
            mkUser
            drvs.mkFolders
          ] ++ extraCopyToRoot;
          perms = [
            (fn.perm {
              inherit uid gid user group;
              path = mkUser;
              regex = "/home/${user}";
            })
            (fn.perm {
              inherit uid gid user group;
              path = drvs.mkFolders;
              regex = "/tmp";
              mode = "1777";
            })
          ] ++ extraPerms ++ (map
            (x: (fn.perm {
              inherit uid gid user group;
              path = mkUser;
              regex = x;
            }))
            extraMkUserPaths);
          layers = map (deps: buildLayer { copyToRoot = [ (pkgs.buildEnv { inherit pathsToLink; name = "layer"; paths = deps; }) ]; }) allLayers;
          initializeNixDatabase = enableNix;
          nixUid = toInt uid;
          nixGid = toInt gid;
        };
    };

  foundry_nix = foundry {
    name = "nix";
    description = "a baseline image with common tools and a working nix install";
    layers = with pkgs; [
      (_base_pkgs pkgs)
    ];
  };

  # python
  _python_pkgs = _python: (pkgs: with pkgs; [
    ruff
    (_python.withPackages
      (p: with p; [
        black
        mypy
        httpx
        requests
        types-requests
      ])
    )
  ]);
  foundry_pypi = foundry {
    name = "pypi";
    description = "a lightweight pypi server with a few backends";
    layers = [
      [
        (pkgs.python311.withPackages (p: with p; [
          passlib
          pypiserver-backend-s3
          pypiserver-pluggable-backends
        ]))
      ]
    ];
  };
  foundry_python_311 = foundry {
    name = "python-3.11";
    description = "a baseline python 3.11 image with common tools and a working nix install";
    layers = [
      (_base_pkgs pkgs)
      (_python_pkgs pkgs.python311 pkgs)
    ];
  };
  foundry_python_312 = foundry {
    name = "python-3.12";
    description = "a baseline python 3.12 image with common tools and a working nix install";
    layers = [
      (_base_pkgs pkgs)
      (_python_pkgs pkgs.python312 pkgs)
    ];
  };
  foundry_python_313 = foundry {
    name = "python-3.13";
    # note: broken at the moment!
    description = "a baseline python 3.13 image with common tools and a working nix install";
    layers = [
      (_base_pkgs pkgs)
      (_python_pkgs pkgs.python313 pkgs)
    ];
  };
  foundry_k8s_aws = foundry {
    name = "k8s-aws";
    description = "a lightweight image with just bash, kubectl, and awscliv2";
    layers = with pkgs; [
      [ (awscli2.override { python3 = python311; }) ]
      [ kubectl ]
    ];
  };
  foundry_certbot_aws = foundry {
    name = "certbot-aws";
    description = "a lightweight image with awscliv2 and certbot configured to work with route53";
    extraMkUser = ''
      mkdir -p $out/etc/letsencrypt $out/var/lib/letsencrypt $out/var/log/letsencrypt
      touch $out/etc/letsencrypt/.keep $out/var/lib/letsencrypt/.keep $out/var/log/letsencrypt/.keep
    '';
    extraMkUserPaths = [
      "/etc/letsencrypt"
      "/var/lib/letsencrypt"
      "/var/log/letsencrypt"
    ];
    layers = with pkgs; [
      [ (awscli2.override { python3 = python311; }) ]
      [
        ((certbot.override { python = python311; }).withPlugins (p: with p; [
          (certbot-dns-route53.overridePythonAttrs (old: {
            pytestFlagsArray = old.pytestFlagsArray ++ [ "-W ignore::DeprecationWarning" ];
          }))
        ]))
      ]
    ];
  };
  foundry_k8s_gcp = foundry {
    name = "k8s-gcp";
    description = "a lightweight image with just bash, kubectl, and gcloud cli";
    layers = with pkgs; [
      [ google-cloud-sdk ]
      [ kubectl ]
    ];
  };
  foundry_zaddy = foundry {
    name = "zaddy";
    description = "a base image with the custom zaddy build with caddy-security, s3proxy and s3browser";
    layers = with pkgs; [ [ zaddy ] ];
  };
  foundry_curl = foundry {
    name = "curl";
    description = "a base image with just curl and basic requirements. does not include nix!";
    layers = with pkgs; [ [ curl ] ];
    enableNix = false;
  };
  foundry_hex = foundry {
    name = "hex";
    description = "a base image with hex and ktools";
    layers = with pkgs; [
      [
        hex
        k8s_pog_scripts
        kubectl
      ]
    ];
  };
  foundry_argo_hex = foundry {
    name = "argohex";
    description = "an argo sidecar image with hex and ktools";
    layers = with pkgs; [
      [
        hex
        hexcast
      ]
    ];
    user = "argocd";
    group = "argocd";
    uid = "999";
    gid = "999";
    extraMkUser = ''
      mkdir -p $out/home/argocd/cmp-server/config
      cp ${./pog/hex/argo/plugin.yaml} $out/home/argocd/cmp-server/config/plugin.yaml
    '';
    extraMkUserPaths = [
      "/home/argocd/cmp-server/config"
    ];
  };
in
{
  inherit foundry;
  foundry_v2 = foundry;
  curl = foundry_curl;
  argohex = foundry_argo_hex;
  hex = foundry_hex;
  k8s_aws = foundry_k8s_aws;
  k8s_gcp = foundry_k8s_gcp;
  certbot_aws = foundry_certbot_aws;
  nix = foundry_nix;
  pypi = foundry_pypi;
  python311 = foundry_python_311;
  python312 = foundry_python_312;
  python313 = foundry_python_313;
  zaddy = foundry_zaddy;
}
