{ pkgs ? import
    (fetchTarball {
      name = "jpetrucciani-2025-09-19";
      url = "https://github.com/jpetrucciani/nix/archive/a98858e842d0dd04a98d081a20646e42826d1f5d.tar.gz";
      sha256 = "06skqwk3zcgbwc9wczbaa18dcrjq3izykvmizqadgwrql6cybk6a";
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
