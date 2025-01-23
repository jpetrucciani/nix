{ pkgs ? import
    (fetchTarball {
      name = "jpetrucciani-2025-01-22";
      url = "https://github.com/jpetrucciani/nix/archive/823936a22b0f0e545b1fa8e88f24343967f18330.tar.gz";
      sha256 = "0d01ipxvgyyr0akyfr6phl080sg5rnsw2bwbffcxrng2yna4z8ap";
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
      figlet
      git
      gron
      jq
      just
      moreutils
      nodePackages.prettier
      scc
      yq-go
      (writeShellScriptBin "hms" ''
        nix-env -i -f ~/cfg.nix
      '')
    ];
    k8s = [
      kubectl
      kubectx
    ];
    nix = [
      nix-direnv
      nixpkgs-fmt
      nixup
    ];
    python = [
      ruff
      (python311.withPackages (p: with p; [
        black
        httpx
      ]))
    ];
    scripts = pkgs.lib.attrsets.attrValues scripts;
  };

  scripts = with pkgs; { };
  paths = pkgs.lib.flatten [ (builtins.attrValues tools) ];
  env = pkgs.buildEnv {
    inherit name paths; buildInputs = paths;
  };
in
(env.overrideAttrs (_: {
  inherit name;
  NIXUP = "0.0.8";
})) // { inherit scripts; }
