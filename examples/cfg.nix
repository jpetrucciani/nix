{ pkgs ? import
    (fetchTarball {
      name = "jpetrucciani-2026-02-24";
      url = "https://github.com/jpetrucciani/nix/archive/c759c89863772065f4c257c56b029d0c67ce0673.tar.gz";
      sha256 = "1wr033lxrcqsizbgmz2p2mhca8wz6c6wsfdmfzfrxx7wzf5r2dmf";
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
      oxfmt
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
      (python314.withPackages (p: with p; [
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
  NIXUP = "0.0.9";
})) // { inherit scripts; }
