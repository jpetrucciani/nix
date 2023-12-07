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
        , pathsToLink ? [ "/bin" "/etc" "/lib" "/share" "/run" ]
        , sysLayer ? true
        , user ? "user"
        , group ? "user"
        , uid ? "1000"
        , gid ? "1000"
        , substituters ? [ "https://jacobi.cachix.org" ]
        , trusted-public-keys ? [ "jacobi.cachix.org-1:JJghCz+ZD2hc9BHO94myjCzf4wS3DeBLKHOz3jCukMU=" ]
        , extraCopyToRoot ? [ ]
        , extraPerms ? [ ]
        , extraMkUser ? ""
        }:
        let
          inherit (pkgs.nix2container.nix2container) buildLayer;
          allLayers = with _layers; [ baseLayer [ mkUser drvs.mkFolders ] ] ++ (optionals sysLayer [ coreLayer ]) ++ (optionals enableNix [ nixLayer ]) ++ layers;
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
            Entrypoint = [ "${drvs.entrypoint}/bin/entrypoint" ];
            Env = env ++ (optionals enableNix [
              "NIX_PAGER=cat"
              "USER=${user}"
              "HOME=/home/${user}"
              "NIX_PATH=nixpkgs=${pkgs.path}"
              "PATH=/home/user/.local/state/nix/profiles/profile/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
              "FOUNDRY=3"
            ]);
            Labels = {
              "org.opencontainers.image.authors" = author;
              "org.opencontainers.image.description" = description;
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
          ] ++ extraPerms;
          layers = map (deps: buildLayer { copyToRoot = [ (pkgs.buildEnv { inherit pathsToLink; name = "layer"; paths = deps; }) ]; }) allLayers;
          initializeNixDatabase = enableNix;
          nixUid = toInt uid;
          nixGid = toInt gid;
        };
    };

  foundryNix = foundry {
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
  foundryPython311 = foundry {
    name = "python-3.11";
    description = "a baseline python 3.11 image with common tools and a working nix install";
    layers = [
      (_base_pkgs pkgs)
      (_python_pkgs pkgs.python311 pkgs)
    ];
  };
  foundryPython312 = foundry {
    name = "python-3.12";
    description = "a baseline python 3.12 image with common tools and a working nix install";
    layers = [
      (_base_pkgs pkgs)
      (_python_pkgs pkgs.python312 pkgs)
    ];
  };
  foundry_k8s_aws = foundry {
    name = "k8s-aws";
    description = "a lightweight image with just bash, kubectl, and awscliv2";
    layers = [
      [ pkgs.awscli2 ]
      [ pkgs.kubectl ]
    ];
  };
  foundry_k8s_gcp = foundry {
    name = "k8s-gcp";
    description = "a lightweight image with just bash, kubectl, and gcloud cli";
    layers = [
      [ pkgs.google-cloud-sdk ]
      [ pkgs.kubectl ]
    ];
  };
  foundry_zaddy = foundry {
    name = "zaddy";
    description = "a base image with the custom zaddy build with caddy-security, s3proxy and s3browser";
    layers = [ [ pkgs.zaddy ] ];
  };
in
{
  inherit foundry;
  foundry_v2 = foundry;
  nix = foundryNix;
  python311 = foundryPython311;
  python312 = foundryPython312;
  k8s_aws = foundry_k8s_aws;
  k8s_gcp = foundry_k8s_gcp;
  zaddy = foundry_zaddy;
}
