{ pkgs ? import
    (fetchTarball {
      name = "jpetrucciani-2023-05-02";
      url = "https://github.com/jpetrucciani/nix/archive/a20807028f42fdc062d42227bd2e7c1c09ea37e1.tar.gz";
      sha256 = "0asbkxf2gzrzmfj6296kkg2lc2bzzsn79nk0k4in84yai0nfc9h4";
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
