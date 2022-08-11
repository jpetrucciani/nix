{ jacobi ? import
    (
      fetchTarball {
        name = "jpetrucciani-2022-08-10";
        url = "https://github.com/jpetrucciani/nix/archive/eb005e0a699426b7493bb48d2b05f823b15546cf.tar.gz";
        sha256 = "0lnhc5x1k7gjcxxqyw793v5jrlhsjgl9n4r2592m0zjkhv5l5m5k";
      }
    )
    { }
}:
let
  name = "cfg";
  tools = with jacobi; {
    cli = [
      bashInteractive_5
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
