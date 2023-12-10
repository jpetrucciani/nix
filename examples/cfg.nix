{ pkgs ? import
    (fetchTarball {
      name = "jpetrucciani-2023-12-10";
      url = "https://github.com/jpetrucciani/nix/archive/32dce848190345e4362d134cdb27577118168791.tar.gz";
      sha256 = "104vdvbykws9fsdzkiha9n4awysv6qd8whaf26ikslw0vdfq676r";
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
env.overrideAttrs (_: {
  NIXUP = "0.0.5";
})
