{ pkgs }:
let
  inherit (pkgs.lib) concatStringsSep genList optionals;
  inherit (pkgs.writers) writeBashBin;
  nixconf = ''
    build-users-group = nixbld
    sandbox = false
    extra-experimental-features = nix-command flakes
    substituters = https://cache.nixos.org/ https://jacobi.cachix.org
    trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= jacobi.cachix.org-1:JJghCz+ZD2hc9BHO94myjCzf4wS3DeBLKHOz3jCukMU=
  '';
  passwd = ''
    root:x:0:0::/root:/bin/bash
    ${concatStringsSep "\n" (genList (i: "nixbld${toString (i+1)}:x:${toString (i+30001)}:30000::/var/empty:/run/current-system/sw/bin/nologin") 32)}
  '';
  group = ''
    root:x:0:
    nogroup:x:65534:
    nixbld:x:30000:${concatStringsSep "," (genList (i: "nixbld${toString (i+1)}") 32)}
  '';
  _base_pkgs = _pkgs: with _pkgs; [
    # deadnix
    # delta
    # dockerTools.caCertificates
    # dyff
    # fd
    # findutils
    # git
    # gnumake
    # gron
    # hex
    # jq
    # just
    # moreutils
    # nixup
    # nixpkgs-fmt
    # openssh
    # scc
    # skopeo
    # statix
    # wget
    # which
    # yq-go
  ];

  foundry_v2 =
    { name
    , layers
    , env ? [ ]
    , registry ? "ghcr.io/jpetrucciani"
    , author ? "j@cobi.dev"
    , description ? "a foundry_v2 docker image built with nix"
    , hostPkgs ? pkgs
    , enableNix ? false
    , pathsToLink ? [ "/bin" ]
    , sysLayer ? true
    }:
    let
      inherit (pkgs.nix2container.nix2container) buildLayer;
      baseLayer = (with pkgs.dockerTools; [
        binSh
        caCertificates
        usrBinEnv
      ]) ++
      (optionals sysLayer (with pkgs; [
        bashInteractive
        coreutils
        curl
        gnugrep
        gnused
        jq
        util-linux
      ] ++ (optionals enableNix [ nix ])));
      allLayers = [ baseLayer ] ++ layers;
    in
    hostPkgs.nix2container.nix2container.buildImage {
      name = "${registry}/${name}";
      config = {
        Env = env ++ (optionals enableNix [
          "NIX_PAGER=cat"
          "USER=nobody"
          "HOME=/"
        ]);
        Labels = {
          "org.opencontainers.image.authors" = author;
          "org.opencontainers.image.description" = description;
        };
      };
      layers = map (deps: buildLayer { copyToRoot = [ (pkgs.buildEnv { inherit pathsToLink; name = "layer"; paths = deps; }) ]; }) allLayers;
      initializeNixDatabase = enableNix;
    };

  foundry =
    { imageName
    , paths
    , command ? "bash"
    , base_pkgs ? _base_pkgs
    , env ? [ ]
    , extraRootCommands ? ""
    , registry ? "ghcr.io/jpetrucciani"
    , workdir ? "/opt/foundry"
    , author ? "j@cobi.dev"
    , description ? "a foundry docker image built with nix"
    , hostPkgs ? pkgs
    , enableNix ? true
    }:
    let
      name = "foundry-${imageName}";
      deps = paths pkgs;
      foundryImage =
        hostPkgs.dockerTools.streamLayeredImage {
          inherit name;
          architecture = "amd64";
          contents = pkgs.buildEnv {
            inherit name;
            paths = [ pkgs.nix ];
            # paths = deps ++ (base_pkgs pkgs) ++ (with pkgs; [
            #   # bashInteractive
            #   # coreutils
            #   # curl
            #   # gnugrep
            #   # gnused
            #   # util-linux
            # ]) ++ (if enableNix then [ pkgs.nix ] else [ ]);
          };
          config = {
            Env = [
              # "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              "USER=nobody"
              "HOME=${workdir}"
            ] ++ (if enableNix then [
              "NIX_PAGER=cat"
              # "NIX_PATH=nixpkgs=${pkgs.path}"
            ] else [ ]) ++ env;
            Labels = {
              "org.opencontainers.image.authors" = author;
              "org.opencontainers.image.description" = description;
            };
            WorkingDir = workdir;
            Cmd = if builtins.isString command then [ command ] else command;
          };
          enableFakechroot = true;
          fakeRootCommands =
            if enableNix then ''
              mkdir -m 1777 -p /tmp /var/tmp
              mkdir -p /etc/nix
              echo '${nixconf}' >/etc/nix/nix.conf
              echo '${passwd}' >/etc/passwd
              echo '${group}' >/etc/group
              ${extraRootCommands}
            '' else null;
          passthru = rec {
            _raw_tag = "$(${raw_tag}/bin/raw_tag)";
            raw_tag = writeBashBin "raw_tag" ''
              echo "${registry}/${name}"
            '';
            _date_tag = "$(${date_tag}/bin/date_tag)";
            date_tag = writeBashBin "date_tag" ''
              echo "$(${raw_tag}/bin/raw_tag):$(${pkgs.coreutils}/bin/date +"%F")"
            '';
            build = writeBashBin "build" ''
              ${foundryImage} | docker load
            '';
            pushToRegistry = writeBashBin "pushToRegistry" ''
              ${foundryImage} |
                ${pkgs.gzip}/bin/gzip --fast |
                ${pkgs.skopeo}/bin/skopeo --insecure-policy copy docker-archive:/dev/stdin "docker://${_date_tag}"
            '';
            tagAsLatest = writeBashBin "tagAsLatest" ''
              ${pkgs.skopeo}/bin/skopeo copy "docker://${_date_tag}" "docker://${_raw_tag}:latest"
            '';
          };
        };
    in
    foundryImage;

  foundryNix = foundry {
    imageName = "nix";
    description = "a baseline image with common tools and a working nix install";
    env = [ ];
    paths = pkgs: with pkgs; [ ];
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
    imageName = "python-3.11";
    description = "a baseline python 3.11 image with common tools and a working nix install";
    paths = _python_pkgs pkgs.python311;
  };
  foundryPython312 = foundry {
    imageName = "python-3.12";
    description = "a baseline python 3.12 image with common tools and a working nix install";
    paths = _python_pkgs pkgs.python312;
  };
  foundry_k8s_aws = foundry_v2 {
    name = "k8s-aws";
    description = "a lightweight image with just bash, kubectl, and awscliv2";
    layers = [
      [ pkgs.awscli2 ]
      [ pkgs.kubectl ]
    ];
  };
  foundry_k8s_gcp = foundry_v2 {
    name = "k8s-gcp";
    description = "a lightweight image with just bash, kubectl, and gcloud cli";
    layers = [
      [ pkgs.google-cloud-sdk ]
      [ pkgs.kubectl ]
    ];
  };
in
{
  inherit foundry foundry_v2;
  nix = foundryNix;
  python311 = foundryPython311;
  python312 = foundryPython312;
  k8s_aws = foundry_k8s_aws;
  k8s_gcp = foundry_k8s_gcp;
}
