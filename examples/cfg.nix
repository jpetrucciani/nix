{ jacobi ? import
    (fetchTarball {
      name = "jpetrucciani-2023-03-16";
      url = "https://github.com/jpetrucciani/nix/archive/3f4f59bbd16b1acb3df5d1a4ad17259b14ce01ac.tar.gz";
      sha256 = "0xn7vipxz95jnsslxdfvm1d73rrsmrvf0z2bxhzjl37xa43zm03y";
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
      fif
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
      (python311.withPackages (p: with p; [
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
