{ jacobi ? import
    (fetchTarball {
      name = "jpetrucciani-2022-12-19";
      url = "https://github.com/jpetrucciani/nix/archive/aeeb4ff7b48518bb9814e5a54187781e4978a8ec.tar.gz";
      sha256 = "1qnmsfdaygh7ilvsdhlcsg5qm83d6fg58zg8bkgcgswq61yjbbbi";
    })
    { }
}:
let
  name = "cfg";
  tools = with jacobi; {
    cli = [
      bashInteractive
      comma
      cowsay
      curl
      delta
      dyff
      figlet
      git
      gron
      jq
      just
      nodePackages.prettier
      scc
      shfmt
      yq-go
      (writeShellScriptBin "hms" ''
        nix-env -i -f ~/cfg.nix
      '')
    ];
    nix = [
      nixpkgs-fmt
      nixup
    ];
    python = [
      (python310.withPackages (p: with p; [
        bandit
        black
        flake8
        mypy
        pylint
        requests
      ]))
    ];
  };

  env = jacobi.enviro {
    inherit name tools;
  };
in
env
