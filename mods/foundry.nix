{ pkgs }:
let
  inherit (pkgs.lib) concatStringsSep genList;
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
    deadnix
    delta
    dockerTools.caCertificates
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
    { imageName
    , paths
    , base_pkgs ? _base_pkgs
    , env ? [ ]
    , registry ? "ghcr.io/jpetrucciani"
    , workdir ? "/opt/foundry"
    , author ? "j@cobi.dev"
    , description ? "a foundry docker image built with nix"
    }:
    let
      name = "foundry-${imageName}";
      deps = paths pkgs;
      foundryImage =
        pkgs.dockerTools.streamLayeredImage {
          inherit name;
          architecture = "amd64";
          contents = pkgs.buildEnv {
            inherit name;
            paths = deps ++ (base_pkgs pkgs) ++ (with pkgs; [
              bashInteractive
              coreutils
              curl
              gnugrep
              gnused
              nix
              util-linux
            ]);
          };
          config = {
            Env = [
              "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              "NIX_PAGER=cat"
              "NIX_PATH=nixpkgs=${pkgs.path}"
              "USER=nobody"
              "HOME=${workdir}"
            ] ++ env;
            Labels = {
              "org.opencontainers.image.authors" = author;
              "org.opencontainers.image.description" = description;
            };
            WorkingDir = workdir;
            Command = "bash";
          };
          enableFakechroot = true;
          fakeRootCommands = ''
            mkdir -m 1777 -p /tmp /var/tmp
            mkdir -p /etc/nix
            echo '${nixconf}' >/etc/nix/nix.conf
            echo '${passwd}' >/etc/passwd
            echo '${group}' >/etc/group
          '';
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
            pushToGHCR = writeBashBin "pushToGHCR" ''
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
in
{
  inherit foundry;
  nix = foundryNix;
  python311 = foundryPython311;
  python312 = foundryPython312;
}
