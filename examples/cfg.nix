{ pkgs ? import
    (fetchTarball {
      name = "jpetrucciani-2023-04-10";
      url = "https://github.com/jpetrucciani/nix/archive/285d3a4956cfe442830b06c30a946790c7429acb.tar.gz";
      sha256 = "1frhaihkr0dbl9zvsr3ifmh4sab22q7rpljj3a9gbp3y8apz60zy";
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
  env = pkgs.buildEnv {
    inherit name paths;
    buildInputs = paths;
  };
in
env
