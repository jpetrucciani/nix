{ pkgs ? import
    (fetchTarball {
      name = "jpetrucciani-2024-03-15";
      url = "https://github.com/jpetrucciani/nix/archive/901e642726b101dfd5ad6fb9f16aa608d2e96efa.tar.gz";
      sha256 = "0083rdr4lqc6hlc3c8n6rkqzxk4qf8b3y73vml1mx16da242d1if";
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
  NIXUP = "0.0.6";
})) // { inherit scripts; }
