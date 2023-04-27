{ pkgs ? import
    (fetchTarball {
      name = "jpetrucciani-2023-04-26";
      url = "https://github.com/jpetrucciani/nix/archive/5f01d3c72d7d2b003debb8d333d654f5a51c2403.tar.gz";
      sha256 = "19kr4d49z54sf8z8llbdc720im07slb3128c0dpqc172hxrnpqwj";
    })
    { }
}:
let
  name = "cfg";
  tools = with pkgs; {
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

  paths = pkgs.lib.flatten [ (builtins.attrValues tools) ];
in
pkgs.buildEnv {
  inherit name paths;
  buildInputs = paths;
}
