{ jacobi ? import
    (fetchTarball {
      name = "jpetrucciani-2023-01-27";
      url = "https://github.com/jpetrucciani/nix/archive/2fbd55e396bd2eb59131c0e6e77f7e5fb0b2a086.tar.gz";
      sha256 = "1gixml2xzmkbgd5p1nbkhbxc3saq9iwp0wljcrbx70gpdvv3llxp";
    })
    { }
}:
let
  name = "cfg";
  tools = with jacobi; {
    cli = [
      bashInteractive
      coreutils
      cowsay
      curl
      delta
      direnv
      dyff
      figlet
      git
      gron
      jq
      just
      moreutils
      nodePackages.prettier
      scc
      yq-go
      hax.comma
      (writeShellScriptBin "hms" ''
        nix-env -i -f ~/cfg.nix
      '')
    ];
    k8s = [
      kubectl
      kubectx
      gke-gcloud-auth-plugin
    ];
    nix = [
      nixpkgs-fmt
      nixup
      nix-direnv
    ];
    python = [
      ruff
      (python310.withPackages (p: with p; [
        black
        mypy
        requests
      ]))
    ];
  };

  env = let paths = jacobi._toolset tools; in
    jacobi.buildEnv {
      inherit name paths;
      buildInputs = paths;
    };
in
env
