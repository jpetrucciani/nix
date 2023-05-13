{ pkgs }:
let
  inherit (pkgs.lib) concatStringsSep genList;
  constants = import ./constants.nix { inherit pkgs; };
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
  foundry = { imageName, paths, env ? [ ], registry ? "ghcr.io/jpetrucciani", workdir ? "/opt/foundry" }:
    let
      name = "foundry-${imageName}";
      deps = paths pkgs;
      foundryImage =
        pkgs.dockerTools.streamLayeredImage {
          inherit name;
          architecture = "amd64";
          contents = pkgs.buildEnv {
            inherit name;
            paths = deps ++ (with pkgs; [
              bashInteractive
              coreutils
              curl
              deadnix
              delta
              dockerTools.caCertificates
              dyff
              fd
              findutils
              git
              gnugrep
              gnumake
              gnused
              gron
              hex
              jq
              just
              moreutils
              nix
              nixup
              nixpkgs-fmt
              openssh
              scc
              skopeo
              statix
              util-linux
              wget
              which
              yq-go
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
          passthru = {
            build = pkgs.writeShellScriptBin "build" ''
              ${foundryImage} | docker load
            '';
            pushToGHCR = pkgs.writeShellScriptBin "pushToGHCR" ''
              ${foundryImage} | \
                ${pkgs.gzip}/bin/gzip --fast | \
                ${pkgs.skopeo}/bin/skopeo --insecure-policy copy docker-archive:/dev/stdin "docker://${registry}/${name}:$(${pkgs.coreutils}/bin/date +"%F")"
            '';
          };
        };
    in
    foundryImage;

  foundryNix = foundry {
    imageName = "nix";
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
        requests
      ])
    )
  ]);
  foundryPython311 = foundry {
    imageName = "python-3.11";
    paths = _python_pkgs pkgs.python311;
  };
  foundryPython312 = foundry {
    imageName = "python-3.12";
    paths = _python_pkgs pkgs.python312;
  };
in
{
  nix = foundryNix;
  python311 = foundryPython311;
  python312 = foundryPython312;
}
